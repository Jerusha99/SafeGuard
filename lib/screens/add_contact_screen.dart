import 'package:flutter/material.dart';
import 'package:safeguard/models/contact.dart' as contact_model;
import 'package:contacts_service_plus/contacts_service_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class AddContactScreen extends StatefulWidget {
  final Function(contact_model.Contact) onAddContact;

  const AddContactScreen({super.key, required this.onAddContact});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickContact() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Request contacts permission
      final permission = await Permission.contacts.request();
      
      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission to access contacts denied'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Try to open contact picker
      final Contact? contact = await ContactsService.openDeviceContactPicker();

      if (mounted && contact != null) {
        // Extract name
        String name = contact.displayName ?? '';
        if (name.isEmpty && contact.givenName != null) {
          name = contact.givenName!;
          if (contact.familyName != null) {
            name += ' ${contact.familyName!}';
          }
        }

        // Extract phone number
        String phoneNumber = '';
        if (contact.phones != null && contact.phones!.isNotEmpty) {
          phoneNumber = contact.phones!.first.value ?? '';
          // Clean phone number (remove non-digits except +)
          phoneNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
        }

        if (name.isNotEmpty || phoneNumber.isNotEmpty) {
          setState(() {
            _nameController.text = name;
            _phoneController.text = phoneNumber;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contact selected successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selected contact has no name or phone number'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (mounted) {
        // User cancelled or no contact selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No contact selected'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing contacts: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _pickContact,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _saveContact() {
    if (_formKey.currentState!.validate()) {
      final newContact = contact_model.Contact(
        id: null,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      widget.onAddContact(newContact);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Emergency Contact'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _pickContact,
                      icon: const Icon(Icons.contacts),
                      label: const Text('Pick from Contacts'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _saveContact,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                      child: const Text('Save Contact'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
