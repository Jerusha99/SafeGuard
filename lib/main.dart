import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safeguard/theme/theme.dart';
import 'package:safeguard/screens/launching_screen.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/services/connectivity_service.dart';
import 'package:safeguard/services/app_update_service.dart';
import 'package:safeguard/services/feedback_service.dart';
import 'package:safeguard/services/notification_service.dart';
import 'package:safeguard/services/supabase_service.dart';
import 'package:safeguard/services/settings_service.dart';
import 'package:safeguard/services/background_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize only essential services synchronously
  await SettingsService.initialize();

  // Start the app immediately to prevent "app not responding"
  runApp(const MyApp());

  // Defer all heavy/network operations to run after app starts
  Future.microtask(() async {
    try {
      // Initialize Supabase (non-blocking, will fail gracefully if offline)
      await SupabaseService.initialize();
    } catch (e) {
      print('Supabase initialization failed (will use local storage): $e');
    }

    try {
      await AnalyticsService.initialize();
    } catch (e) {
      print('Analytics initialization failed: $e');
    }

    try {
      // Initialize background service for shake detection and voice monitoring
      await initializeService();
    } catch (e) {
      print('Background service initialization failed: $e');
    }

    try {
      await ConnectivityService().initialize();
    } catch (e) {
      print('Connectivity service initialization failed: $e');
    }

    try {
      await AppUpdateService().initialize();
    } catch (e) {
      print('App update service initialization failed: $e');
    }

    try {
      await FeedbackService().initialize();
    } catch (e) {
      print('Feedback service initialization failed: $e');
    }

    // Initialize notification service asynchronously (this is slow)
    try {
      await NotificationService().initialize();
      await NotificationService().scheduleMorningGreeting();
      await NotificationService().scheduleNightGreeting();
      await NotificationService().scheduleSafetyReminder();
    } catch (e) {
      print('Notification service initialization failed: $e');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
      valueListenable: ThemeController.instance.theme,
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'SafeGuard',
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: const LaunchingScreen(),
        );
      },
    );
  }
}
