import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/utils/logger.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  PackageInfo? _packageInfo;

  Future<void> initialize() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
      AppLogger.info('Feedback Service initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize feedback service: $e');
    }
  }

  Future<void> showFeedbackDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.feedback, color: Colors.blue),
              SizedBox(width: 8),
              Flexible(child: Text('Share Your Feedback')),
            ],
          ),
          content: Column( // Removed const here because children are no longer const
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('We value your feedback! Help us improve SafeGuard by:'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: const Text('Rating the app')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: const Text('Reporting bugs')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: const Text('Suggesting features')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.share, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: const Text('Sharing with friends')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rateApp(context);
              },
              child: const Text('Rate App'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _sendFeedback(context);
              },
              child: const Text('Send Feedback'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    try {
      await AnalyticsService.logUserEngagement('rate_app_clicked');
      
      // For Android, open Play Store
      const String packageName = 'com.safeguard.app'; // Replace with actual package name
      final Uri playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');
      
      if (await canLaunchUrl(playStoreUri)) {
        await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Play Store'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to open Play Store: $e');
      await AnalyticsService.recordError(e, null);
    }
  }

  Future<void> _sendFeedback(BuildContext context) async {
    try {
      final String platformName = Theme.of(context).platform.name;
      await AnalyticsService.logUserEngagement('send_feedback_clicked');
      final String subject = 'SafeGuard Feedback - ${_packageInfo?.version ?? '1.0.0'}';
      final String body = '''
Hi Jerusha's Tech Team,

I would like to share feedback about SafeGuard:

[Please describe your feedback, suggestions, or report any issues here]

App Version: ${_packageInfo?.version ?? '1.0.0'}
Build Number: ${_packageInfo?.buildNumber ?? '1'}
Device: $platformName

Thank you for your time!

Best regards,
[Your Name]
''';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'feedback@jerushastech.com',
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        // Fallback: copy to clipboard
        if (context.mounted) {
          await _copyToClipboard(context, body);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to send feedback: $e');
      await AnalyticsService.recordError(e, null);
    }
  }

  Future<void> shareApp(BuildContext context) async {
    try {
      await AnalyticsService.logUserEngagement('share_app_clicked');
      
      final String shareText = '''
🚨 SafeGuard - Emergency SOS & Safety App 🚨

Keep yourself and your loved ones safe with SafeGuard!

✨ Features:
• Emergency SOS alerts with location sharing
• Emergency contact management
• Fake call functionality for safety
• Voice-activated emergency triggers
• Shake-to-SOS detection
• Quick emergency messages
• Safety resources and information

Download now: https://play.google.com/store/apps/details?id=com.safeguard.app

Developed by Jerusha's Tech
#SafeGuard #Safety #Emergency #SOS
''';

      await Share.share(
        shareText,
        subject: 'SafeGuard - Emergency Safety App',
      );
    } catch (e) {
      AppLogger.error('Failed to share app: $e');
      await AnalyticsService.recordError(e, null);
    }
  }

  Future<void> _copyToClipboard(BuildContext context, String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback text copied to clipboard'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to copy to clipboard: $e');
    }
  }

  Future<void> showBugReportDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController bugController = TextEditingController();
        
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.bug_report, color: Colors.red),
              SizedBox(width: 8),
              Flexible(child: Text('Report a Bug')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please describe the bug you encountered:'),
              const SizedBox(height: 12),
              TextField(
                controller: bugController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the bug, steps to reproduce, and expected behavior...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (bugController.text.trim().isNotEmpty) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    await _sendBugReport(context, bugController.text);
                  }
                }
              },
              child: const Text('Send Report'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendBugReport(BuildContext context, String bugDescription) async {
    try {
      final String platformName = Theme.of(context).platform.name;
      await AnalyticsService.logUserEngagement('bug_report_sent');
      final String subject = 'SafeGuard Bug Report - ${_packageInfo?.version ?? '1.0.0'}';
      final String body = '''
Bug Report for SafeGuard:

Description:
$bugDescription

App Information:
Version: ${_packageInfo?.version ?? '1.0.0'}
Build: ${_packageInfo?.buildNumber ?? '1'}
Platform: $platformName

Please provide any additional details that might help us reproduce and fix this issue.

Thank you for helping us improve SafeGuard!
''';

      final Uri emailUri = Uri(
        scheme: 'mailto',
        path: 'bugs@jerushastech.com',
        query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
      );

      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (context.mounted) {
          await _copyToClipboard(context, body);
        }
      }
    } catch (e) {
      AppLogger.error('Failed to send bug report: $e');
      await AnalyticsService.recordError(e, null);
    }
  }
}
