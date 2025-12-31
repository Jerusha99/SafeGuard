import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:safeguard/services/feedback_service.dart';
import 'package:safeguard/services/app_update_service.dart';
import 'package:safeguard/services/connectivity_service.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/widgets/bubble_background.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  PackageInfo? _packageInfo;
  String _deviceInfo = '';
  bool _isOnline = false;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadAppInfo();
    _checkConnectivity();
    AnalyticsService.logScreenView('about_screen');
  }

  void _checkConnectivity() {
    _connectivityService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      setState(() {
        _packageInfo = packageInfo;
        _deviceInfo =
            'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
      });
    } catch (e) {
      setState(() {
        _deviceInfo = 'Device info unavailable';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  void _showDeveloperInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.business, color: Colors.blue),
              SizedBox(width: 8),
              Text('Jerusha\'s Tech'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Jerusha\'s Tech',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Jerusha\'s Tech is a leading mobile app development company specializing in safety and security applications. We are committed to creating innovative solutions that protect and empower users.',
              ),
              SizedBox(height: 16),
              Text(
                'Our Mission:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'To develop cutting-edge mobile applications that enhance personal safety and provide peace of mind through technology.',
              ),
              SizedBox(height: 16),
              Text(
                'Contact Information:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Email: contact@jerushastech.com'),
              Text('Website: www.jerushastech.com'),
              Text('Phone: +1 (555) 123-4567'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _launchUrl('mailto:contact@jerushastech.com');
              },
              child: const Text('Contact Us'),
            ),
          ],
        );
      },
    );
  }

  void _showAppFeatures() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('App Features'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureItem(
                  Icons.sos,
                  'Emergency SOS',
                  'Quick emergency alerts with location sharing',
                ),
                _buildFeatureItem(
                  Icons.contacts,
                  'Emergency Contacts',
                  'Manage and organize emergency contacts',
                ),
                _buildFeatureItem(
                  Icons.call,
                  'Fake Call',
                  'Simulate incoming calls for safety',
                ),
                _buildFeatureItem(
                  Icons.record_voice_over,
                  'Voice Activation',
                  'Voice-triggered emergency alerts',
                ),
                _buildFeatureItem(
                  Icons.vibration,
                  'Shake Detection',
                  'Shake device to trigger emergency',
                ),
                _buildFeatureItem(
                  Icons.location_on,
                  'Location Sharing',
                  'Automatic location sharing in emergencies',
                ),
                _buildFeatureItem(
                  Icons.message,
                  'Quick Messages',
                  'Pre-configured emergency messages',
                ),
                _buildFeatureItem(
                  Icons.article,
                  'Safety Resources',
                  'Emergency information and resources',
                ),
                _buildFeatureItem(
                  Icons.security,
                  'Background Monitoring',
                  'Continuous safety monitoring',
                ),
                _buildFeatureItem(
                  Icons.palette,
                  'Customizable Themes',
                  'Personalize app appearance',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About SafeGuard'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: BubbleBackground()),
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Logo and Name
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'app_logo',
                    child: ClipOval(
                      child: Image.asset(
                        'lib/logoSafeguard.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.security,
                            size: 60,
                            color: Theme.of(context).colorScheme.onPrimary,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // App Name and Version
                Text(
                  'SafeGuard',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _packageInfo?.version ?? 'Version 1.0.0',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Build ${_packageInfo?.buildNumber ?? '1'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 30),

                // Developer Information Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Icon(
                                Icons.business,
                                color: Colors.blue,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Developed by',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Text(
                                    'Jerusha\'s Tech',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Leading mobile app development company specializing in safety and security applications.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _showDeveloperInfo,
                              icon: const Icon(Icons.info_outline),
                              label: const Text('Learn More'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _launchUrl('mailto:contact@jerushastech.com'),
                              icon: const Icon(Icons.email),
                              label: const Text('Contact'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // App Information Card
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          'Package Name',
                          _packageInfo?.packageName ?? 'com.safeguard.app',
                        ),
                        _buildInfoRow(
                          'Version',
                          _packageInfo?.version ?? '1.0.0',
                        ),
                        _buildInfoRow(
                          'Build Number',
                          _packageInfo?.buildNumber ?? '1',
                        ),
                        _buildInfoRow('Device Info', _deviceInfo),
                        _buildInfoRow('Platform', 'Android'),
                        _buildInfoRow('Flutter Version', '3.8.1+'),
                        _buildInfoRow(
                          'Connection',
                          _isOnline
                              ? 'Online (${_connectivityService.getConnectionTypeString()})'
                              : 'Offline',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Enhanced Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showAppFeatures,
                        icon: const Icon(Icons.star),
                        label: const Text('Features'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            FeedbackService().showFeedbackDialog(context),
                        icon: const Icon(Icons.feedback),
                        label: const Text('Feedback'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            AppUpdateService().showUpdateDialog(context),
                        icon: const Icon(Icons.system_update),
                        label: const Text('Check Updates'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => FeedbackService().shareApp(context),
                        icon: const Icon(Icons.share),
                        label: const Text('Share App'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _launchUrl('https://www.jerushastech.com'),
                        icon: const Icon(Icons.language),
                        label: const Text('Website'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            FeedbackService().showBugReportDialog(context),
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Report Bug'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Copyright Information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '© 2024 Jerusha\'s Tech',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'All rights reserved. SafeGuard is a trademark of Jerusha\'s Tech.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Made with ❤️ for your safety',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _copyToClipboard(value),
              child: Text(
                value,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
