import 'package:flutter/material.dart';
import 'package:safeguard/models/contact.dart';
import 'package:safeguard/screens/add_contact_screen.dart';
import 'package:safeguard/services/contacts_service.dart';
import 'package:safeguard/utils/logger.dart';
import 'dart:async';
import 'package:safeguard/widgets/bubble_background.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final List<Contact> _contacts = [];
  StreamSubscription? _contactsSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _contactsSubscription?.cancel();
    super.dispose();
  }

  void _loadContacts() async {
    try {
      await ContactsService.initialize();
      final contacts = await ContactsService.loadContacts();
      if (!mounted) return;
      setState(() {
        _contacts.clear();
        _contacts.addAll(contacts);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading contacts: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to connect to server. Working in offline mode.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _addContact(Contact contact) async {
    try {
      final success = await ContactsService.addContact(contact);
      if (!mounted) return;

      if (success) {
        // Reload contacts to get updated list
        _loadContacts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact added successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add contact'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error adding contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add contact: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteContact(int index) async {
    if (index >= _contacts.length) return;
    final contactToDelete = _contacts[index];

    try {
      final success = await ContactsService.deleteContact(contactToDelete);
      if (!mounted) return;

      if (success) {
        // Reload contacts to get updated list
        _loadContacts();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact deleted successfully'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete contact'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Error deleting contact: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete contact: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: Stack(
        children: [
          const Positioned.fill(child: BubbleBackground()),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _contacts.isEmpty
              ? Center(
                  child: Text(
                    'No contacts added yet.\nPress the + button to add your first contact.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    final contact = _contacts[index];
                    return ListTile(
                      title: Text(contact.name),
                      subtitle: Text(contact.phoneNumber),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteContact(index),
                      ),
                    );
                  },
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddContactScreen(onAddContact: _addContact),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
