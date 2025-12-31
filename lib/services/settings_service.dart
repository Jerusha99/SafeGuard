import 'package:safeguard/models/app_settings.dart';
import 'package:safeguard/services/device_id_service.dart';
import 'package:safeguard/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static AppSettings? _cachedSettings;
  static SharedPreferences? _prefs;

  // Keys for SharedPreferences
  static const String _keyVoiceDetection = 'voice_detection_enabled';
  static const String _keyVoiceKeywords = 'voice_keywords';
  static const String _keyShakeToSos = 'shake_to_sos';
  static const String _keyLocationInSos = 'location_in_sos';
  static const String _keyQuickMsgHelp = 'quick_msg_help';
  static const String _keyQuickMsgNoSignal = 'quick_msg_no_signal';
  static const String _keyQuickMsgComing = 'quick_msg_coming';
  static const String _keyNotificationsEnabled = 'notifications_enabled';

  /// Initialize SharedPreferences
  static Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('SettingsService initialized');
    } catch (e) {
      AppLogger.error('Error initializing SettingsService: $e');
    }
  }

  /// Load app settings from local storage only
  /// Note: Supabase sync is disabled as the app_settings table doesn't exist
  static Future<AppSettings> loadSettings() async {
    if (_prefs == null) await initialize();

    try {
      final deviceId = await DeviceIdService.getOrCreateDeviceId();

      // Load from local storage
      final localSettings = await _loadFromLocalStorage(deviceId);
      if (localSettings != null) {
        _cachedSettings = localSettings;
        AppLogger.info('Settings loaded from local storage');
        return localSettings;
      }

      // Create default settings
      final defaultSettings = AppSettings(deviceId: deviceId);
      await saveSettings(defaultSettings);
      _cachedSettings = defaultSettings;
      AppLogger.info('Created default settings');
      return defaultSettings;
    } catch (e) {
      AppLogger.error('Error loading settings: $e');
      final deviceId = await DeviceIdService.getOrCreateDeviceId();
      return AppSettings(deviceId: deviceId);
    }
  }

  /// Save app settings to local storage only
  /// Note: Supabase sync is disabled as the app_settings table doesn't exist
  static Future<void> saveSettings(AppSettings settings) async {
    if (_prefs == null) await initialize();

    try {
      // Always save to local storage
      await _saveToLocalStorage(settings);
      _cachedSettings = settings;
      AppLogger.info('Settings saved to local storage');
    } catch (e) {
      AppLogger.error('Error saving settings: $e');
      rethrow;
    }
  }

  /// Update specific setting
  static Future<void> updateVoiceDetection(bool enabled) async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      final updatedSettings = settings.copyWith(voiceDetectionEnabled: enabled);
      await saveSettings(updatedSettings);
    } catch (e) {
      AppLogger.error('Error updating voice detection: $e');
    }
  }

  /// Update voice keywords
  static Future<void> updateVoiceKeywords(List<String> keywords) async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      final updatedSettings = settings.copyWith(voiceKeywords: keywords);
      await saveSettings(updatedSettings);
    } catch (e) {
      AppLogger.error('Error updating voice keywords: $e');
    }
  }

  /// Update notifications setting
  static Future<void> updateNotifications(bool enabled) async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      final updatedSettings = settings.copyWith(notificationsEnabled: enabled);
      await saveSettings(updatedSettings);
    } catch (e) {
      AppLogger.error('Error updating notifications: $e');
    }
  }

  /// Update emergency contact
  static Future<void> updateEmergencyContact(String? contact) async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      final updatedSettings = settings.copyWith(emergencyContact: contact);
      await saveSettings(updatedSettings);
    } catch (e) {
      AppLogger.error('Error updating emergency contact: $e');
    }
  }

  /// Get cached settings (or load if not cached)
  static Future<AppSettings> getSettings() async {
    return _cachedSettings ?? await loadSettings();
  }

  /// Clear cache
  static void clearCache() {
    _cachedSettings = null;
  }

  /// Listen to real-time settings updates from Supabase
  /// Note: This is disabled as the app_settings table doesn't exist in Supabase
  /// All settings are stored locally using SharedPreferences
  static Stream<AppSettings> listenToSettings() async* {
    // Return a stream that yields the current settings once and then completes
    // This prevents the app from trying to listen to a non-existent table
    try {
      final settings = await loadSettings();
      yield settings;
    } catch (e) {
      AppLogger.error('Error loading settings: $e');
    }
  }

  // Local storage helpers
  static Future<void> _saveToLocalStorage(AppSettings settings) async {
    if (_prefs == null) await initialize();

    await _prefs!.setBool(_keyVoiceDetection, settings.voiceDetectionEnabled);
    await _prefs!.setString(
      _keyVoiceKeywords,
      settings.voiceKeywords.join(','),
    );
    await _prefs!.setBool(
      _keyNotificationsEnabled,
      settings.notificationsEnabled,
    );
    await _prefs!.setBool(_keyShakeToSos, settings.shakeToSos);
    await _prefs!.setBool(_keyLocationInSos, settings.locationInSos);
    await _prefs!.setString(_keyQuickMsgHelp, settings.quickMsgHelp);
    await _prefs!.setString(_keyQuickMsgNoSignal, settings.quickMsgNoSignal);
    await _prefs!.setString(_keyQuickMsgComing, settings.quickMsgComing);
    AppLogger.info('Settings saved to local storage');
  }

  static Future<AppSettings?> _loadFromLocalStorage(String deviceId) async {
    if (_prefs == null) await initialize();

    final voiceDetection = _prefs!.getBool(_keyVoiceDetection);
    if (voiceDetection == null) return null; // No local settings

    final keywordsStr =
        _prefs!.getString(_keyVoiceKeywords) ?? 'help,emergency';
    final keywords = keywordsStr
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return AppSettings(
      deviceId: deviceId,
      voiceDetectionEnabled: voiceDetection,
      voiceKeywords: keywords.isEmpty ? ['help', 'emergency'] : keywords,
      notificationsEnabled: _prefs!.getBool(_keyNotificationsEnabled) ?? true,
      shakeToSos: _prefs!.getBool(_keyShakeToSos) ?? true,
      locationInSos: _prefs!.getBool(_keyLocationInSos) ?? true,
      quickMsgHelp: _prefs!.getString(_keyQuickMsgHelp) ?? 'Help me!',
      quickMsgNoSignal:
          _prefs!.getString(_keyQuickMsgNoSignal) ??
          'No signal. I might be offline.',
      quickMsgComing: _prefs!.getString(_keyQuickMsgComing) ?? "I'm coming",
    );
  }

  // Quick message getters and setters
  static Future<String> getQuickMsgHelp() async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      return settings.quickMsgHelp;
    } catch (e) {
      AppLogger.error('Error getting quick msg help: $e');
      return 'Help me!';
    }
  }

  static Future<String> getQuickMsgNoSignal() async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      return settings.quickMsgNoSignal;
    } catch (e) {
      AppLogger.error('Error getting quick msg no signal: $e');
      return 'No signal. I might be offline.';
    }
  }

  static Future<String> getQuickMsgComing() async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      return settings.quickMsgComing;
    } catch (e) {
      AppLogger.error('Error getting quick msg coming: $e');
      return "I'm coming";
    }
  }

  static Future<void> saveQuickMessages({
    required String help,
    required String noSignal,
    required String coming,
  }) async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      final updatedSettings = settings.copyWith(
        quickMsgHelp: help,
        quickMsgNoSignal: noSignal,
        quickMsgComing: coming,
      );
      await saveSettings(updatedSettings);
      AppLogger.info('Quick messages saved');
    } catch (e) {
      AppLogger.error('Error saving quick messages: $e');
      rethrow;
    }
  }

  // Safety triggers
  static Future<bool> getShakeToSos() async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      return settings.shakeToSos;
    } catch (e) {
      AppLogger.error('Error getting shake to SOS: $e');
      return true;
    }
  }

  static Future<bool> getLocationInSos() async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      return settings.locationInSos;
    } catch (e) {
      AppLogger.error('Error getting location in SOS: $e');
      return true;
    }
  }

  static Future<void> saveShakeToSos(bool enabled) async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      final updatedSettings = settings.copyWith(shakeToSos: enabled);
      await saveSettings(updatedSettings);
      AppLogger.info('Shake to SOS saved: $enabled');
    } catch (e) {
      AppLogger.error('Error saving shake to SOS: $e');
      rethrow;
    }
  }

  static Future<void> saveLocationInSos(bool enabled) async {
    try {
      final settings = _cachedSettings ?? await loadSettings();
      final updatedSettings = settings.copyWith(locationInSos: enabled);
      await saveSettings(updatedSettings);
      AppLogger.info('Location in SOS saved: $enabled');
    } catch (e) {
      AppLogger.error('Error saving location in SOS: $e');
      rethrow;
    }
  }
}
