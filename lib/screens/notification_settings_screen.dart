import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safeguard/services/notification_service.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/utils/logger.dart';
import 'package:safeguard/widgets/bubble_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Morning notification settings
  TimeOfDay _morningTime = const TimeOfDay(hour: 8, minute: 0);
  bool _morningEnabled = true;

  // Night notification settings
  TimeOfDay _nightTime = const TimeOfDay(hour: 22, minute: 0);
  bool _nightEnabled = true;

  // Safety reminder settings
  bool _safetyReminderEnabled = true;
  int _safetyReminderInterval = 3; // days

  // General settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSettings();
    AnalyticsService.logScreenView('notification_settings_screen');
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _morningEnabled = prefs.getBool('morning_notification_enabled') ?? true;
        _nightEnabled = prefs.getBool('night_notification_enabled') ?? true;
        _safetyReminderEnabled = prefs.getBool('safety_reminder_enabled') ?? true;
        _safetyReminderInterval = prefs.getInt('safety_reminder_interval') ?? 3;
        _soundEnabled = prefs.getBool('notification_sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('notification_vibration_enabled') ?? true;

        final morningHour = prefs.getInt('morning_notification_hour') ?? 8;
        final morningMinute = prefs.getInt('morning_notification_minute') ?? 0;
        _morningTime = TimeOfDay(hour: morningHour, minute: morningMinute);

        final nightHour = prefs.getInt('night_notification_hour') ?? 22;
        final nightMinute = prefs.getInt('night_notification_minute') ?? 0;
        _nightTime = TimeOfDay(hour: nightHour, minute: nightMinute);
      });
    } catch (e) {
      AppLogger.error('Failed to load notification settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('morning_notification_enabled', _morningEnabled);
      await prefs.setBool('night_notification_enabled', _nightEnabled);
      await prefs.setBool('safety_reminder_enabled', _safetyReminderEnabled);
      await prefs.setInt('safety_reminder_interval', _safetyReminderInterval);
      await prefs.setBool('notification_sound_enabled', _soundEnabled);
      await prefs.setBool('notification_vibration_enabled', _vibrationEnabled);
      await prefs.setInt('morning_notification_hour', _morningTime.hour);
      await prefs.setInt('morning_notification_minute', _morningTime.minute);
      await prefs.setInt('night_notification_hour', _nightTime.hour);
      await prefs.setInt('night_notification_minute', _nightTime.minute);

      // Reschedule notifications with new settings
      await NotificationService().rescheduleAllNotifications();
      
      AnalyticsService.logCustomEvent('notification_settings_updated', {
        'morning_enabled': _morningEnabled,
        'night_enabled': _nightEnabled,
        'safety_reminder_enabled': _safetyReminderEnabled,
      });

      HapticFeedback.lightImpact();
      _showSuccessSnackBar();
    } catch (e) {
      AppLogger.error('Failed to save notification settings: $e');
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Settings saved successfully!'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _selectTime(BuildContext context, bool isMorning) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isMorning ? _morningTime : _nightTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.red,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isMorning) {
          _morningTime = picked;
        } else {
          _nightTime = picked;
        }
      });
      await _saveSettings();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: BubbleBackground()),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                children: [
                  // Header Card
                  _buildHeaderCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Morning Notifications
                  _buildNotificationSection(
                    title: 'Morning Greetings',
                    subtitle: 'Daily morning safety reminders',
                    icon: Icons.wb_sunny,
                    color: Colors.orange,
                    children: [
                      _buildSwitchTile(
                        title: 'Enable Morning Notifications',
                        subtitle: 'Receive daily morning safety tips',
                        value: _morningEnabled,
                        onChanged: (value) {
                          setState(() {
                            _morningEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      if (_morningEnabled) ...[
                        const SizedBox(height: 8),
                        _buildTimeTile(
                          title: 'Notification Time',
                          subtitle: 'When to receive morning greetings',
                          time: _morningTime,
                          onTap: () => _selectTime(context, true),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Night Notifications
                  _buildNotificationSection(
                    title: 'Night Greetings',
                    subtitle: 'Daily night safety reminders',
                    icon: Icons.nights_stay,
                    color: Colors.indigo,
                    children: [
                      _buildSwitchTile(
                        title: 'Enable Night Notifications',
                        subtitle: 'Receive daily night safety tips',
                        value: _nightEnabled,
                        onChanged: (value) {
                          setState(() {
                            _nightEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      if (_nightEnabled) ...[
                        const SizedBox(height: 8),
                        _buildTimeTile(
                          title: 'Notification Time',
                          subtitle: 'When to receive night greetings',
                          time: _nightTime,
                          onTap: () => _selectTime(context, false),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Safety Reminders
                  _buildNotificationSection(
                    title: 'Safety Reminders',
                    subtitle: 'Periodic safety check-ins',
                    icon: Icons.security,
                    color: Colors.green,
                    children: [
                      _buildSwitchTile(
                        title: 'Enable Safety Reminders',
                        subtitle: 'Get reminded to check your safety settings',
                        value: _safetyReminderEnabled,
                        onChanged: (value) {
                          setState(() {
                            _safetyReminderEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      if (_safetyReminderEnabled) ...[
                        const SizedBox(height: 8),
                        _buildIntervalTile(),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notification Preferences
                  _buildNotificationSection(
                    title: 'Notification Preferences',
                    subtitle: 'Customize notification behavior',
                    icon: Icons.settings,
                    color: Colors.purple,
                    children: [
                      _buildSwitchTile(
                        title: 'Sound',
                        subtitle: 'Play sound for notifications',
                        value: _soundEnabled,
                        onChanged: (value) {
                          setState(() {
                            _soundEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                      _buildSwitchTile(
                        title: 'Vibration',
                        subtitle: 'Vibrate for notifications',
                        value: _vibrationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _vibrationEnabled = value;
                          });
                          _saveSettings();
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Test Notification Button
                  _buildTestNotificationButton(),
                  
                  const SizedBox(height: 16),
                  
                  // Preview Card
                  _buildPreviewCard(),
                ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.notifications_active,
              size: 60,
              color: Colors.red.shade600,
            ),
            const SizedBox(height: 16),
            const Text(
              'Notification Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customize your safety reminders and greetings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: Colors.red.shade600,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              time.format(context),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade600,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reminder Interval',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'How often to receive safety reminders',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _safetyReminderInterval.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  onChanged: (value) {
                    setState(() {
                      _safetyReminderInterval = value.round();
                    });
                    _saveSettings();
                  },
                  activeColor: Colors.red.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_safetyReminderInterval day${_safetyReminderInterval == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestNotificationButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          await NotificationService().showInstantNotification(
            title: 'Test Notification 🧪',
            body: 'This is a test notification from SafeGuard!',
            payload: 'test_notification',
          );
          AnalyticsService.logUserEngagement('test_notification_sent');
        },
        icon: const Icon(Icons.notifications),
        label: const Text('Send Test Notification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                const Text(
                  'Notification Preview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Good Morning! ☀️',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getMorningMessage(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Scheduled for ${_morningTime.format(context)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMorningMessage() {
    return 'Start your day safely! Remember to share your location with trusted contacts.';
  }
}
