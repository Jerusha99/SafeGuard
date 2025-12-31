import 'package:safeguard/models/contact.dart';
import 'package:safeguard/services/supabase_service.dart';
import 'package:safeguard/services/device_id_service.dart';
import 'package:safeguard/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ContactsService {
  static final SupabaseService _supabaseService = SupabaseService();
  static SharedPreferences? _prefs;
  static const String _keyContacts = 'emergency_contacts_local';

  /// Initialize SharedPreferences
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('ContactsService initialized');
    } catch (e) {
      AppLogger.error('Error initializing ContactsService: $e');
    }
  }

  /// Load contacts from local storage and Supabase
  static Future<List<Contact>> loadContacts() async {
    if (_prefs == null) await initialize();

    try {
      final deviceId = await DeviceIdService.getOrCreateDeviceId();

      // Try loading from Supabase first (silent mode since we have local fallback)
      try {
        final contactsData = await _supabaseService.readDataOnce(
          'emergency_contacts',
          deviceId: deviceId,
          silent:
              true, // Suppress error logging since we have local storage fallback
        );

        if (contactsData.isNotEmpty) {
          final contacts = contactsData
              .map(
                (data) => Contact(
                  id: data['id']?.toString(),
                  name: data['name'] ?? '',
                  phoneNumber: data['phone_number'] ?? '',
                ),
              )
              .toList();

          // Save to local storage
          await _saveToLocalStorage(contacts);
          AppLogger.info('Contacts loaded from Supabase: ${contacts.length}');
          return contacts;
        }
      } catch (e) {
        // Silently fall back to local storage (network errors are expected when offline)
        // Error already suppressed in readDataOnce with silent: true
      }

      // Fallback to local storage
      final localContacts = await _loadFromLocalStorage();
      if (localContacts.isNotEmpty) {
        AppLogger.info(
          'Contacts loaded from local storage: ${localContacts.length}',
        );
        return localContacts;
      }

      AppLogger.info('No contacts found');
      return [];
    } catch (e) {
      AppLogger.error('Error loading contacts: $e');
      return await _loadFromLocalStorage();
    }
  }

  /// Save contacts to both Supabase and local storage
  static Future<void> saveContacts(List<Contact> contacts) async {
    if (_prefs == null) await initialize();

    try {
      // Always save to local storage first
      await _saveToLocalStorage(contacts);
      AppLogger.info('Contacts saved to local storage: ${contacts.length}');

      // Note: We don't sync all contacts at once to avoid conflicts
      // Individual add/delete operations handle Supabase sync
    } catch (e) {
      AppLogger.error('Error saving contacts: $e');
    }
  }

  /// Add a contact
  static Future<bool> addContact(Contact contact) async {
    if (_prefs == null) await initialize();

    try {
      // Load existing contacts
      final contacts = await loadContacts();

      // Add new contact
      contacts.add(contact);

      // Save to local storage
      await _saveToLocalStorage(contacts);

      // Try to sync with Supabase
      try {
        final deviceId = await DeviceIdService.getOrCreateDeviceId();
        final contactData = {
          'name': contact.name,
          'phone_number': contact.phoneNumber,
          'device_id': deviceId,
        };
        final id = await _supabaseService.pushData(
          'emergency_contacts',
          contactData,
        );
        if (id != null) {
          // Update local contact with Supabase ID
          final index = contacts.indexWhere(
            (c) =>
                c.name == contact.name &&
                c.phoneNumber == contact.phoneNumber &&
                c.id == contact.id,
          );
          if (index >= 0) {
            contacts[index] = Contact(
              id: id,
              name: contact.name,
              phoneNumber: contact.phoneNumber,
              deviceId: contact.deviceId,
            );
            await _saveToLocalStorage(contacts);
            AppLogger.info('Contact added to Supabase: $id');
          }
        }
      } catch (e) {
        AppLogger.warning('Could not sync contact to Supabase: $e');
      }

      AppLogger.info('Contact added locally: ${contact.name}');
      return true;
    } catch (e) {
      AppLogger.error('Error adding contact: $e');
      return false;
    }
  }

  /// Delete a contact
  static Future<bool> deleteContact(Contact contact) async {
    if (_prefs == null) await initialize();

    try {
      // Load existing contacts
      final contacts = await loadContacts();

      // Remove contact
      contacts.removeWhere(
        (c) => c.id == contact.id && c.phoneNumber == contact.phoneNumber,
      );

      // Save to local storage
      await _saveToLocalStorage(contacts);

      // Try to delete from Supabase
      if (contact.id != null) {
        try {
          await _supabaseService.removeData('emergency_contacts', contact.id!);
          AppLogger.info('Contact deleted from Supabase: ${contact.id}');
        } catch (e) {
          AppLogger.warning('Could not delete contact from Supabase: $e');
        }
      }

      AppLogger.info('Contact deleted locally: ${contact.name}');
      return true;
    } catch (e) {
      AppLogger.error('Error deleting contact: $e');
      return false;
    }
  }

  /// Get emergency contact phone numbers
  static Future<List<String>> getEmergencyPhoneNumbers() async {
    try {
      final contacts = await loadContacts();
      return contacts
          .map((c) => c.phoneNumber.trim())
          .where((phone) => phone.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting emergency phone numbers: $e');
      return [];
    }
  }

  // Local storage helpers
  static Future<void> _saveToLocalStorage(List<Contact> contacts) async {
    if (_prefs == null) await initialize();

    try {
      final contactsJson = contacts
          .map(
            (c) => {'id': c.id, 'name': c.name, 'phone_number': c.phoneNumber},
          )
          .toList();

      await _prefs!.setString(_keyContacts, jsonEncode(contactsJson));
      AppLogger.info('Contacts saved to local storage: ${contacts.length}');
    } catch (e) {
      AppLogger.error('Error saving contacts to local storage: $e');
    }
  }

  static Future<List<Contact>> _loadFromLocalStorage() async {
    if (_prefs == null) await initialize();

    try {
      final contactsJsonStr = _prefs!.getString(_keyContacts);
      if (contactsJsonStr == null || contactsJsonStr.isEmpty) {
        return [];
      }

      final contactsJson = jsonDecode(contactsJsonStr) as List;
      final contacts = contactsJson
          .map(
            (data) => Contact(
              id: data['id']?.toString(),
              name: data['name'] ?? '',
              phoneNumber: data['phone_number'] ?? '',
            ),
          )
          .toList();

      return contacts;
    } catch (e) {
      AppLogger.error('Error loading contacts from local storage: $e');
      return [];
    }
  }
}
