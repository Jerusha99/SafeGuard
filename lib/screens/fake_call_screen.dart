import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safeguard/screens/fake_incoming_call_screen.dart';
import 'package:safeguard/widgets/bubble_background.dart';
import 'package:safeguard/services/analytics_service.dart';

class FakeCallScreen extends StatefulWidget {
  const FakeCallScreen({super.key});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  final TextEditingController _contactNameController = TextEditingController(
    text: 'Mom',
  );
  final TextEditingController _phoneNumberController = TextEditingController(
    text: '+94 77 123 4567',
  );
  int _callDuration = 30; // seconds
  bool _enableVibration = true;
  bool _enableSound = true;
  String _selectedRingtone = 'Default';

  final List<String> _ringtones = [
    'Default',
    'Classic',
    'Modern',
    'Gentle',
    'Urgent',
  ];

  final List<Map<String, dynamic>> _quickContacts = [
    {'name': 'Mom', 'number': '+94 77 123 4567', 'avatar': '👩'},
    {'name': 'Dad', 'number': '+94 77 234 5678', 'avatar': '👨'},
    {'name': 'Sister', 'number': '+94 77 345 6789', 'avatar': '👧'},
    {'name': 'Brother', 'number': '+94 77 456 7890', 'avatar': '👦'},
    {'name': 'Best Friend', 'number': '+94 77 567 8901', 'avatar': '👫'},
    {'name': 'Emergency Contact', 'number': '+94 77 678 9012', 'avatar': '🚨'},
  ];

  @override
  void initState() {
    super.initState();
    AnalyticsService.logScreenView('fake_call_screen');
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _triggerFakeCall() {
    HapticFeedback.mediumImpact();
    AnalyticsService.logFakeCallUsed();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FakeIncomingCallScreen(
          contactName: _contactNameController.text.isNotEmpty
              ? _contactNameController.text
              : 'Unknown',
          phoneNumber: _phoneNumberController.text,
          callDuration: _callDuration,
          enableVibration: _enableVibration,
          enableSound: _enableSound,
          ringtone: _selectedRingtone,
        ),
      ),
    );
  }

  void _selectQuickContact(Map<String, dynamic> contact) {
    setState(() {
      _contactNameController.text = contact['name'];
      _phoneNumberController.text = contact['number'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fake Call'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: BubbleBackground()),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.phone_android,
                          size: 60,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Fake Call Generator',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create realistic fake calls for safety situations',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Contacts
                Text(
                  'Quick Contacts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _quickContacts[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => _selectQuickContact(contact),
                          child: Container(
                            width: 80,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  contact['avatar'],
                                  style: const TextStyle(fontSize: 30),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  contact['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Contact Details
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contact Name
                        TextField(
                          controller: _contactNameController,
                          decoration: InputDecoration(
                            labelText: 'Contact Name',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).inputDecorationTheme.fillColor,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Phone Number
                        TextField(
                          controller: _phoneNumberController,
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).inputDecorationTheme.fillColor,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Settings
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Call Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Call Duration
                        Text(
                          'Call Duration: ${_callDuration}s',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Slider(
                          value: _callDuration.toDouble(),
                          min: 10,
                          max: 120,
                          divisions: 11,
                          onChanged: (value) {
                            setState(() {
                              _callDuration = value.round();
                            });
                          },
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 16),

                        // Ringtone Selection
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRingtone,
                          decoration: InputDecoration(
                            labelText: 'Ringtone',
                            prefixIcon: const Icon(Icons.music_note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Theme.of(
                              context,
                            ).inputDecorationTheme.fillColor,
                          ),
                          items: _ringtones.map((String ringtone) {
                            return DropdownMenuItem<String>(
                              value: ringtone,
                              child: Text(ringtone),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedRingtone = newValue!;
                            });
                          },
                        ),

                        const SizedBox(height: 16),

                        // Vibration Toggle
                        SwitchListTile(
                          title: const Text('Enable Vibration'),
                          subtitle: const Text(
                            'Phone will vibrate during call',
                          ),
                          value: _enableVibration,
                          onChanged: (value) {
                            setState(() {
                              _enableVibration = value;
                            });
                          },
                          activeTrackColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),

                        // Sound Toggle
                        SwitchListTile(
                          title: const Text('Enable Sound'),
                          subtitle: const Text('Phone will play ringtone'),
                          value: _enableSound,
                          onChanged: (value) {
                            setState(() {
                              _enableSound = value;
                            });
                          },
                          activeTrackColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Trigger Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _triggerFakeCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Trigger Fake Call',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Safety Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).dividerColor.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Use this feature responsibly and only in genuine safety situations.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
