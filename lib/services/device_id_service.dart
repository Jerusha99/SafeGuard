import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceIdService {
  static const String _prefsKey = 'device_id';

  static Future<String> getOrCreateDeviceId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? existing = prefs.getString(_prefsKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final String newId = _generateRandomId();
    await prefs.setString(_prefsKey, newId);
    return newId;
  }

  static String _generateRandomId() {
    final Random random = Random.secure();
    const String alphabet =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < 24; i++) {
      buffer.write(alphabet[random.nextInt(alphabet.length)]);
    }
    return buffer.toString();
  }
}


