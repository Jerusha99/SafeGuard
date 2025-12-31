import 'package:flutter/foundation.dart';
import 'package:safeguard/utils/logger.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  static Future<void> initialize() async {
    try {
      // Set up basic error handling without Firebase
      FlutterError.onError = (FlutterErrorDetails details) {
        AppLogger.error('Flutter Error: ${details.exception}', details.exception);
      };
      
      // Set up platform error handling
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error('Platform Error: $error', error);
        return true;
      };
      
      AppLogger.info('Analytics service initialized (local logging only)');
    } catch (e) {
      AppLogger.error('Failed to initialize analytics: $e');
    }
  }

  // Analytics Events - Now just log locally
  static Future<void> logAppOpened() async {
    try {
      AppLogger.info('Analytics: App opened at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log app opened: $e');
    }
  }

  static Future<void> logSosTriggered(String triggerType) async {
    try {
      AppLogger.info('Analytics: SOS triggered by $triggerType at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log SOS triggered: $e');
    }
  }

  static Future<void> logContactAdded() async {
    try {
      AppLogger.info('Analytics: Contact added at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log contact added: $e');
    }
  }

  static Future<void> logFakeCallUsed() async {
    try {
      AppLogger.info('Analytics: Fake call used at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log fake call used: $e');
    }
  }

  static Future<void> logSettingsChanged(String settingName, dynamic value) async {
    try {
      AppLogger.info('Analytics: Setting changed - $settingName: $value at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log settings changed: $e');
    }
  }

  static Future<void> logScreenView(String screenName) async {
    try {
      AppLogger.info('Analytics: Screen viewed - $screenName at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log screen view: $e');
    }
  }

  static Future<void> logUserEngagement(String action) async {
    try {
      AppLogger.info('Analytics: User engagement - $action at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log user engagement: $e');
    }
  }

  // Error Recording - Now just log locally
  static Future<void> recordError(dynamic error, StackTrace? stackTrace, {bool fatal = false}) async {
    try {
      AppLogger.error('Analytics: Error recorded${fatal ? ' (FATAL)' : ''}: $error', error);
      if (stackTrace != null) {
        AppLogger.error('Stack trace: $stackTrace');
      }
    } catch (e) {
      AppLogger.error('Failed to record error: $e');
    }
  }

  static Future<void> setUserId(String userId) async {
    try {
      AppLogger.info('Analytics: User ID set to $userId at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to set user ID: $e');
    }
  }

  static Future<void> setCustomKey(String key, dynamic value) async {
    try {
      AppLogger.info('Analytics: Custom key set - $key: $value at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to set custom key: $e');
    }
  }

  static Future<void> logCustomEvent(String eventName, Map<String, Object> parameters) async {
    try {
      AppLogger.info('Analytics: Custom event - $eventName with parameters: $parameters at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log custom event: $e');
    }
  }

  // App Performance Monitoring
  static Future<void> logAppPerformance(String metric, int value) async {
    try {
      AppLogger.info('Analytics: App performance - $metric: $value at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log app performance: $e');
    }
  }

  // User Properties
  static Future<void> setUserProperty(String name, String value) async {
    try {
      AppLogger.info('Analytics: User property set - $name: $value at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to set user property: $e');
    }
  }

  // App Update Tracking
  static Future<void> logAppUpdate(String fromVersion, String toVersion) async {
    try {
      AppLogger.info('Analytics: App updated from $fromVersion to $toVersion at ${DateTime.now()}');
    } catch (e) {
      AppLogger.error('Failed to log app update: $e');
    }
  }
}