import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safeguard/utils/logger.dart';
import 'package:flutter/services.dart';

class SmsService {
  // Channel removed as it's not being used
  static const MethodChannel _channel = MethodChannel('sendSms');

  static Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      AppLogger.info('Attempting to send SMS directly to: $phoneNumber');
      final bool granted = await requestSmsPermission();
      if (!granted) {
        AppLogger.warning('SMS permission not granted, fallback to launcher');
        return _openSmsApp(phoneNumber, message);
      }

      // Direct send using platform channel to native Android (SmsManager)
      await _channel.invokeMethod('send', {
        'phone': phoneNumber,
        'message': message,
      });
      AppLogger.info('Direct SMS send invoked successfully');
      return true;
    } catch (e) {
      AppLogger.error('Direct SMS send failed, falling back to launcher', e);
      return _openSmsApp(phoneNumber, message);
    }
  }

  static Future<bool> _openSmsApp(String phoneNumber, String message) async {
    try {
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasSmsPermission() async {
    final status = await Permission.sms.status;
    AppLogger.info('SMS permission status: $status');
    return status.isGranted;
  }

  static Future<bool> requestSmsPermission() async {
    // Request both SEND_SMS and READ_PHONE_STATE depending on OEMs
    final permission = await Permission.sms.request();
    return permission.isGranted;
  }
}
