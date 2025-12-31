import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safeguard/utils/logger.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/services/feedback_service.dart';
import 'package:safeguard/widgets/bubble_background.dart';
import 'package:safeguard/services/app_update_service.dart';
import 'package:safeguard/screens/notification_settings_screen.dart';
import 'package:safeguard/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _quickMsgHelpController = TextEditingController(
    text: 'Help me!',
  );
  final TextEditingController _quickMsgNoSignalController =
      TextEditingController(text: 'No signal. I might be offline.');
  final TextEditingController _quickMsgComingController = TextEditingController(
    text: "I'm coming",
  );
  final TextEditingController _voiceKeywordsController = TextEditingController(
    text: 'help, emergency',
  );
  bool _shakeToSos = true;
  bool _voiceTrigger = true;
  bool _locationInSos = true;
  // Removed Supabase service for now - using local storage approach

  @override
  void initState() {
    super.initState();
    _loadSettingsFromStorage();
    AnalyticsService.logScreenView('settings_screen');
  }

  Future<void> _loadSettingsFromStorage() async {
    try {
      // Load all settings from SettingsService (from Supabase)
      final settings = await SettingsService.getSettings();

      if (!mounted) return;
      setState(() {
        _shakeToSos = settings.shakeToSos;
        _voiceTrigger = settings.voiceDetectionEnabled;
        _locationInSos = settings.locationInSos;
        _voiceKeywordsController.text = settings.voiceKeywords.join(', ');
        _quickMsgHelpController.text = settings.quickMsgHelp;
        _quickMsgNoSignalController.text = settings.quickMsgNoSignal;
        _quickMsgComingController.text = settings.quickMsgComing;
      });

      AppLogger.info('Settings loaded successfully from Supabase');
    } catch (e) {
      AppLogger.error('Error loading settings: $e');
    }
  }

  Future<void> _saveQuickMessages() async {
    try {
      // Get current settings and update quick messages
      final settings = await SettingsService.getSettings();
      final updatedSettings = settings.copyWith(
        quickMsgHelp: _quickMsgHelpController.text,
        quickMsgNoSignal: _quickMsgNoSignalController.text,
        quickMsgComing: _quickMsgComingController.text,
      );
      await SettingsService.saveSettings(updatedSettings);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick messages saved to Supabase!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('Error saving quick messages: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveToggles() async {
    try {
      // Get current settings
      final settings = await SettingsService.getSettings();

      // Update with new values
      final updatedSettings = settings.copyWith(
        shakeToSos: _shakeToSos,
        locationInSos: _locationInSos,
        voiceDetectionEnabled: _voiceTrigger,
      );

      // Save to Supabase
      await SettingsService.saveSettings(updatedSettings);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safety triggers saved to Supabase!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('Error saving toggles: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveVoiceKeywords() async {
    try {
      final keywordsText = _voiceKeywordsController.text.trim();
      final keywords = keywordsText
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();

      if (keywords.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one keyword'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get current settings and update voice keywords
      final settings = await SettingsService.getSettings();
      final updatedSettings = settings.copyWith(voiceKeywords: keywords);
      await SettingsService.saveSettings(updatedSettings);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice keywords saved to Supabase: ${keywords.join(", ")}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      AppLogger.error('Error saving voice keywords: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.locationWhenInUse,
      Permission.phone,
      Permission.microphone,
      Permission.sms,
    ].request();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Status'),
          content: SingleChildScrollView(
            child: ListBody(
              children: statuses.entries.map((entry) {
                return Text(
                  '${entry.key.toString().split('.').last}: ${entry.value}',
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Stack(
        children: [
          const Positioned.fill(child: BubbleBackground()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: <Widget>[
                const SizedBox(height: 10),
                const Text(
                  'Safety Triggers',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SwitchListTile(
                  title: const Text('Shake to trigger SOS'),
                  value: _shakeToSos,
                  onChanged: (v) => setState(() => _shakeToSos = v),
                ),
                SwitchListTile(
                  title: const Text('Voice trigger ("help" / "emergency")'),
                  value: _voiceTrigger,
                  onChanged: (v) => setState(() => _voiceTrigger = v),
                ),
                SwitchListTile(
                  title: const Text('Include location in SOS'),
                  value: _locationInSos,
                  onChanged: (v) => setState(() => _locationInSos = v),
                ),
                ElevatedButton(
                  onPressed: _saveToggles,
                  child: const Text('Save Triggers'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _voiceKeywordsController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Voice keywords (comma separated)',
                    helperText: 'Example: help, emergency, danger',
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _saveVoiceKeywords,
                  child: const Text('Save Voice Keywords'),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Quick Messages',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _quickMsgHelpController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Help me message',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _quickMsgNoSignalController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'No signal message',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _quickMsgComingController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "I'm coming message",
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _saveQuickMessages,
                  child: const Text('Save Quick Messages'),
                ),
                const SizedBox(height: 30),
                const Text(
                  'App Permissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _requestPermissions,
                  child: const Text('Request All Permissions'),
                ),
                const SizedBox(height: 30),

                // Enhanced Features Section
                const Text(
                  'Enhanced Features',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Colors.purple,
                    ),
                    title: const Text('Notification Settings'),
                    subtitle: const Text(
                      'Customize morning and night greetings',
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.feedback, color: Colors.blue),
                    title: const Text('Send Feedback'),
                    subtitle: const Text('Share your thoughts and suggestions'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => FeedbackService().showFeedbackDialog(context),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.system_update,
                      color: Colors.green,
                    ),
                    title: const Text('Check for Updates'),
                    subtitle: const Text('Get the latest version of SafeGuard'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => AppUpdateService().showUpdateDialog(context),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.share, color: Colors.orange),
                    title: const Text('Share App'),
                    subtitle: const Text('Tell friends about SafeGuard'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => FeedbackService().shareApp(context),
                  ),
                ),

                Card(
                  child: ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.red),
                    title: const Text('Report Bug'),
                    subtitle: const Text('Help us fix issues'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => FeedbackService().showBugReportDialog(context),
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
