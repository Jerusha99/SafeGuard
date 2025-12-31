import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:safeguard/utils/logger.dart';

Future<void> initializeService() async {
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
  
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: true,
      autoStart: true,
    ),
    iosConfiguration: IosConfiguration(
      onBackground: onIosBackground,
      onForeground: onStart,
      autoStart: true,
    ),
  );
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use the correct way to register plugins
  if (kIsWeb) {
    // No-op for web
  } else {
    // For non-web platforms
    DartPluginRegistrant.ensureInitialized();
  }

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    DartPluginRegistrant.ensureInitialized();
  }

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
  }

  // Update notification whenever the service receives a foreground command
  service.on('update').listen((event) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "SafeGuard Running",
        content: "Monitoring for emergencies",
      );
    }
  });

  // Function to trigger SOS actions
  @pragma('vm:entry-point')
  Future<void> triggerSosActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emergencyContact = prefs.getString('emergencyContact');

      if (emergencyContact == null || emergencyContact.isEmpty) {
        AppLogger.info('Emergency contact not set in background service.');
        return;
      }

      final locationStatus = await Permission.location.request();
      final smsStatus = await Permission.sms.request();

      if (locationStatus.isGranted && smsStatus.isGranted) {
        Position? position;
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 20),
            ),
          );
        } on TimeoutException catch (_) {
          // Fallback: try last known position if current fix timed out
          position = await Geolocator.getLastKnownPosition();
          if (position == null) {
            AppLogger.warning('Location timeout and no last known position.');
            return;
          }
        }
        final locationUrl =
            'https://maps.google.com/?q=${position.latitude},${position.longitude}';

        // Create SOS message
        final sosMessage =
            '🚨 EMERGENCY SOS 🚨\n\n'
            'I need immediate help!\n\n'
            '📍 My location: $locationUrl\n'
            '🕐 Time: ${DateTime.now().toString()}\n\n'
            'Please call me back or contact emergency services.';

        // Open SMS app with pre-filled message
        bool smsSent = false;
        try {
          final smsUri = Uri.parse(
            'sms:$emergencyContact?body=${Uri.encodeComponent(sosMessage)}',
          );
          if (await canLaunchUrl(smsUri)) {
            await launchUrl(smsUri, mode: LaunchMode.externalApplication);
            smsSent = true;
            AppLogger.info('SMS app opened from background');
          } else {
            AppLogger.warning('Could not open SMS app from background');
          }
        } catch (e) {
          AppLogger.error('Error opening SMS app from background', e);
        }

        AppLogger.info(
          'SOS triggered from background! SMS sent: $smsSent, Location: ${position.latitude}, ${position.longitude}',
        );
      } else {
        AppLogger.warning(
          'Location or SMS permission not granted for background SOS.',
        );
      }
    } catch (e) {
      AppLogger.error('Error in background SOS', e);
    }
  }

  // Set up foreground/background listeners
  // These listeners are for the UI to send commands to the service, not for the service to set its own mode.
  // The foreground mode is primarily set during configuration and can be toggled via FlutterBackgroundService().setAsForegroundMode(true/false)

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Shake detection logic - require continuous shaking for ~4 seconds,
  // then notify UI to prompt the user (do not auto-send SOS here).
  final double shakeThreshold = 30.0; // squared magnitude threshold
  bool isAboveThreshold = false;
  DateTime? thresholdStartAt;
  DateTime? lastNotifiedAt;
  const Duration requiredDuration = Duration(seconds: 4);
  const Duration notifyCooldown = Duration(seconds: 12);
  // Guards to avoid repeated notifications and false positives
  DateTime? lastBelowThresholdAt;
  DateTime? cooldownUntil;
  const Duration minIdleBeforeNewSequence = Duration(seconds: 2);
  const Duration postNotifyGlobalCooldown = Duration(seconds: 60);

  accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval).listen((
    AccelerometerEvent event,
  ) async {
    final double currentAcceleration =
        (event.x * event.x + event.y * event.y + event.z * event.z);

    if (currentAcceleration > shakeThreshold) {
      // Respect global cooldown
      if (cooldownUntil != null && DateTime.now().isBefore(cooldownUntil!)) {
        return;
      }

      if (!isAboveThreshold) {
        // Only start a new sequence if idle for a bit
        final now = DateTime.now();
        final bool idleLongEnough = lastBelowThresholdAt != null &&
            now.difference(lastBelowThresholdAt!) >= minIdleBeforeNewSequence;
        if (!idleLongEnough) {
          return;
        }
        isAboveThreshold = true;
        thresholdStartAt = now;
        AppLogger.info('Shake started');
      } else {
        // already above threshold, check duration
        if (thresholdStartAt != null) {
          final elapsed = DateTime.now().difference(thresholdStartAt!);
          final bool cooledDown =
              lastNotifiedAt == null ||
              DateTime.now().difference(lastNotifiedAt!) > notifyCooldown;
          if (elapsed >= requiredDuration && cooledDown) {
            lastNotifiedAt = DateTime.now();
            AppLogger.info('Continuous shake detected for 4s, notifying UI.');
            if (await Vibration.hasVibrator() == true) {
              Vibration.vibrate(duration: 800);
            }
            // Notify Flutter side to show confirmation dialog and open mic
            try {
              service.invoke('shakeDetected', {
                'action': 'shakeDetected',
                'timestamp': DateTime.now().toIso8601String(),
              });
            } catch (e) {
              AppLogger.error('Error invoking shakeDetected event', e);
            }
            // Apply post-notify cooldown and reset sequence
            cooldownUntil = DateTime.now().add(postNotifyGlobalCooldown);
            thresholdStartAt = null;
            isAboveThreshold = false;
          }
        }
      }
    } else {
      // dropped below threshold => reset
      if (isAboveThreshold) {
        AppLogger.debug('Shake ended / below threshold');
      }
      isAboveThreshold = false;
      thresholdStartAt = null;
      lastBelowThresholdAt = DateTime.now();
    }
  });
}
