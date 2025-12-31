import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/utils/logger.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Notification IDs
  static const int morningNotificationId = 1001;
  static const int nightNotificationId = 1002;
  static const int safetyReminderId = 1003;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android initialization settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      AppLogger.info('Notification service initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize notification service: $e');
    }
  }
  
  // Lazy timezone initialization - only call when needed
  void _ensureTimezonesLoaded() {
    try {
      tz.initializeTimeZones();
    } catch (e) {
      // Already initialized, ignore
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.info('Notification tapped: ${response.payload}');
    AnalyticsService.logCustomEvent('notification_tapped', {
      'notification_id': response.payload ?? 'unknown',
      'action': response.actionId ?? 'none',
    });
  }

  Future<void> scheduleMorningGreeting() async {
    try {
      _ensureTimezonesLoaded(); // Load timezones lazily
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('morning_notification_hour') ?? 8;
      final minute = prefs.getInt('morning_notification_minute') ?? 0;
      final isEnabled = prefs.getBool('morning_notification_enabled') ?? true;

      if (!isEnabled) return;

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If the time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _notifications.zonedSchedule(
        morningNotificationId,
        'Good Morning! ☀️',
        _getMorningMessage(),
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getMorningNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'morning_greeting',
        );
      } on Object {
        // Fallback to inexact alarm if exact alarms are not permitted
        await _notifications.zonedSchedule(
          morningNotificationId,
          'Good Morning! ☀️',
          _getMorningMessage(),
          tz.TZDateTime.from(scheduledDate, tz.local),
          _getMorningNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'morning_greeting',
        );
      }

      AppLogger.info('Morning greeting scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      AppLogger.error('Failed to schedule morning greeting: $e');
    }
  }

  Future<void> scheduleNightGreeting() async {
    try {
      _ensureTimezonesLoaded(); // Load timezones lazily
      final prefs = await SharedPreferences.getInstance();
      final hour = prefs.getInt('night_notification_hour') ?? 22;
      final minute = prefs.getInt('night_notification_minute') ?? 0;
      final isEnabled = prefs.getBool('night_notification_enabled') ?? true;

      if (!isEnabled) return;

      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If the time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _notifications.zonedSchedule(
        nightNotificationId,
        'Good Night! 🌙',
        _getNightMessage(),
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getNightNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'night_greeting',
        );
      } on Object catch (_) {
        await _notifications.zonedSchedule(
          nightNotificationId,
          'Good Night! 🌙',
          _getNightMessage(),
          tz.TZDateTime.from(scheduledDate, tz.local),
          _getNightNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'night_greeting',
        );
      }

      AppLogger.info('Night greeting scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      AppLogger.error('Failed to schedule night greeting: $e');
    }
  }

  Future<void> scheduleSafetyReminder() async {
    try {
      _ensureTimezonesLoaded(); // Load timezones lazily
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('safety_reminder_enabled') ?? true;
      final interval = prefs.getInt('safety_reminder_interval') ?? 3; // days

      if (!isEnabled) return;

      final now = DateTime.now();
      final scheduledDate = now.add(Duration(days: interval));

      try {
        await _notifications.zonedSchedule(
        safetyReminderId,
        'Safety Check-in 📱',
        'Remember to update your emergency contacts and check your safety settings.',
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getSafetyReminderDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'safety_reminder',
        );
      } on Object catch (_) {
        await _notifications.zonedSchedule(
          safetyReminderId,
          'Safety Check-in 📱',
          'Remember to update your emergency contacts and check your safety settings.',
          tz.TZDateTime.from(scheduledDate, tz.local),
          _getSafetyReminderDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: 'safety_reminder',
        );
      }

      AppLogger.info('Safety reminder scheduled for ${scheduledDate.toString()}');
    } catch (e) {
      AppLogger.error('Failed to schedule safety reminder: $e');
    }
  }

  String _getMorningMessage() {
    final messages = [
      'Start your day safely! Remember to share your location with trusted contacts.',
      'Good morning! Check your emergency contacts and stay aware of your surroundings.',
      'Morning safety tip: Always let someone know your plans for the day.',
      'Have a safe day! Keep your emergency contacts updated and easily accessible.',
      'Good morning! Your safety matters - stay connected and stay safe.',
    ];
    return messages[DateTime.now().day % messages.length];
  }

  String _getNightMessage() {
    final messages = [
      'Good night! Make sure your emergency contacts are up to date.',
      'Sleep well! Remember to keep your phone charged for emergencies.',
      'Night safety tip: Always lock your doors and windows before sleeping.',
      'Good night! Stay safe and have a peaceful rest.',
      'Sweet dreams! Your safety app is here to protect you.',
    ];
    return messages[DateTime.now().day % messages.length];
  }

  NotificationDetails _getMorningNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'morning_greetings',
        'Morning Greetings',
        channelDescription: 'Daily morning safety reminders and greetings',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFE57373),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        actions: [
          AndroidNotificationAction('open_app', 'Open App', showsUserInterface: true),
          AndroidNotificationAction('dismiss', 'Dismiss'),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'morning_greeting',
      ),
    );
  }

  NotificationDetails _getNightNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'night_greetings',
        'Night Greetings',
        channelDescription: 'Daily night safety reminders and greetings',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF5C6BC0),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        actions: [
          AndroidNotificationAction('open_app', 'Open App', showsUserInterface: true),
          AndroidNotificationAction('dismiss', 'Dismiss'),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'night_greeting',
      ),
    );
  }

  NotificationDetails _getSafetyReminderDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'safety_reminders',
        'Safety Reminders',
        channelDescription: 'Periodic safety check-in reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        styleInformation: BigTextStyleInformation(''),
        actions: [
          AndroidNotificationAction('check_settings', 'Check Settings', showsUserInterface: true),
          AndroidNotificationAction('dismiss', 'Dismiss'),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'safety_reminder',
      ),
    );
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    try {
      await _notifications.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'instant_notifications',
            'Instant Notifications',
            channelDescription: 'Immediate notifications from SafeGuard',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            color: const Color(0xFFF44336),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: BigTextStyleInformation(''),
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        payload: payload,
      );
    } catch (e) {
      AppLogger.error('Failed to show instant notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    AppLogger.info('All notifications cancelled');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    AppLogger.info('Notification $id cancelled');
  }

  Future<void> rescheduleAllNotifications() async {
    await cancelAllNotifications();
    await scheduleMorningGreeting();
    await scheduleNightGreeting();
    await scheduleSafetyReminder();
    AppLogger.info('All notifications rescheduled');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
