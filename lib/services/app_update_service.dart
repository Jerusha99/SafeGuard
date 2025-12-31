import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/utils/logger.dart';

class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._internal();
  factory AppUpdateService() => _instance;
  AppUpdateService._internal();

  PackageInfo? _packageInfo;
  String? _currentVersion;
  String? _latestVersion;

  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      _currentVersion = _packageInfo?.version;
      AppLogger.info('App Update Service initialized - Current version: $_currentVersion');
    } catch (e) {
      AppLogger.error('Failed to initialize app update service: $e');
    }
  }

  Future<bool> checkForUpdates({bool showDialog = true}) async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability != UpdateAvailability.updateAvailable) {
        AppLogger.info('No updates available');
        if (showDialog) {
          _showNoUpdateDialog();
        }
        return false;
      }

      AppLogger.info('Update available');
      await AnalyticsService.logCustomEvent('update_available', {
        'current_version': _currentVersion ?? 'unknown',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      if (showDialog) {
        _showUpdateDialog();
      }
      return true;
    } catch (e) {
      AppLogger.error('Failed to check for updates: $e');
      await AnalyticsService.recordError(e, null);
      return false;
    }
  }

  Future<bool> performImmediateUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          await AnalyticsService.logCustomEvent('immediate_update_performed', {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          return true;
        } else {
          AppLogger.info('Immediate update not allowed, need flexible update');
          return false;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to perform immediate update: $e');
      await AnalyticsService.recordError(e, null);
      return false;
    }
  }

  Future<bool> performFlexibleUpdate() async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await AnalyticsService.logCustomEvent('flexible_update_started', {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          });
          return true;
        } else {
          AppLogger.info('Flexible update not allowed, need immediate update');
          return false;
        }
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to perform flexible update: $e');
      await AnalyticsService.recordError(e, null);
      return false;
    }
  }

  Future<void> completeFlexibleUpdate() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
      await AnalyticsService.logCustomEvent('flexible_update_completed', {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      AppLogger.error('Failed to complete flexible update: $e');
      await AnalyticsService.recordError(e, null);
    }
  }

  void _showUpdateDialog() {
    // This would typically be called from a context where you have access to BuildContext
    // For now, we'll just log the action
    AppLogger.info('Update dialog should be shown');
  }

  void _showNoUpdateDialog() {
    // This would typically be called from a context where you have access to BuildContext
    // For now, we'll just log the action
    AppLogger.info('No update dialog should be shown');
  }

  Future<void> showUpdateDialog(BuildContext context) async {
    try {
      AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();
      
      if (!context.mounted) return;
      
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.system_update, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Update Available'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('A new version of SafeGuard is available!'),
                  const SizedBox(height: 8),
                  Text('Current version: $_currentVersion'),
                  const SizedBox(height: 8),
                  const Text('Please update to get the latest features and security improvements.'),
                ],
              ),
              actions: [
                if (updateInfo.flexibleUpdateAllowed)
                  TextButton(
                    onPressed: () async {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        await performFlexibleUpdate();
                      }
                    },
                    child: const Text('Update Later'),
                  ),
                if (updateInfo.immediateUpdateAllowed)
                  ElevatedButton(
                    onPressed: () async {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        await performImmediateUpdate();
                      }
                    },
                    child: const Text('Update Now'),
                  ),
                if (!updateInfo.immediateUpdateAllowed && !updateInfo.flexibleUpdateAllowed)
                  ElevatedButton(
                    onPressed: () {
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        // Open Play Store manually since openAppStore is not available
                        _openPlayStore();
                      }
                    },
                    child: const Text('Update in Store'),
                  ),
              ],
            );
          },
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You are using the latest version!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to show update dialog: $e');
      await AnalyticsService.recordError(e, null);
    }
  }

  void _openPlayStore() {
    // This would typically open the Play Store
    // For now, we'll just log the action
    AppLogger.info('Play Store should be opened for app update');
  }

  String? get currentVersion => _currentVersion;
  String? get latestVersion => _latestVersion;
}
