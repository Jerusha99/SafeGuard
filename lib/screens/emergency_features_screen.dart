import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/services/sms_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyFeaturesScreen extends StatefulWidget {
  const EmergencyFeaturesScreen({super.key});

  @override
  State<EmergencyFeaturesScreen> createState() =>
      _EmergencyFeaturesScreenState();
}

class _EmergencyFeaturesScreenState extends State<EmergencyFeaturesScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;

  bool _isEmergencyActive = false;
  Position? _currentPosition;
  String? _emergencyContact;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadEmergencyContact();
    AnalyticsService.logScreenView('emergency_features_screen');
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  Future<void> _loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emergencyContact = prefs.getString('emergencyContact');
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final permission = await Permission.location.request();
      if (permission.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      AnalyticsService.recordError(e, null);
    }
  }

  Future<void> _triggerEmergency() async {
    if (_isEmergencyActive) return;

    setState(() {
      _isEmergencyActive = true;
    });

    _pulseController.repeat(reverse: true);
    _shakeController.forward();
    HapticFeedback.heavyImpact();

    AnalyticsService.logSosTriggered('emergency_sos_button');

    // Get current location
    await _getCurrentLocation();

    // Send emergency SMS if contact is available
    if (_emergencyContact != null && _currentPosition != null) {
      await _sendEmergencySMS();
    }

    // Show emergency dialog
    _showEmergencyDialog();
  }

  Future<void> _sendEmergencySMS() async {
    try {
      final locationUrl =
          'https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
      final message =
          '''
🚨 EMERGENCY SOS 🚨

I need immediate help!

📍 My location: $locationUrl
🕐 Time: ${DateTime.now().toString()}

Please call me back or contact emergency services.
''';

      await SmsService.sendSms(_emergencyContact!, message);
    } catch (e) {
      AnalyticsService.recordError(e, null);
    }
  }

  void _showEmergencyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: 8),
              Text('Emergency Activated'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Emergency SOS has been activated!'),
              const SizedBox(height: 16),
              if (_emergencyContact != null)
                Text('SMS sent to: $_emergencyContact'),
              if (_currentPosition != null)
                Text(
                  'Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deactivateEmergency();
              },
              child: const Text('Deactivate'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _callEmergencyServices();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Call 119'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callEmergencyServices() async {
    try {
      final Uri callUri = Uri.parse('tel:119');
      if (await canLaunchUrl(callUri)) {
        await launchUrl(callUri);
      }
    } catch (e) {
      AnalyticsService.recordError(e, null);
    }
  }

  void _deactivateEmergency() {
    setState(() {
      _isEmergencyActive = false;
    });
    _pulseController.stop();
    _shakeController.reset();
    AnalyticsService.logCustomEvent('emergency_deactivated', {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Features'),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isEmergencyActive
                ? [Colors.red.shade900, Colors.red.shade700, Colors.black]
                : [Colors.orange.shade50, Colors.white],
            stops: _isEmergencyActive
                ? const [0.0, 0.3, 0.3]
                : const [0.0, 0.2],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Emergency SOS Button
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: _isEmergencyActive
                          ? [Colors.red.shade600, Colors.red.shade800]
                          : [Colors.red.shade500, Colors.red.shade700],
                    ),
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: AnimatedBuilder(
                              animation: _shakeAnimation,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset: Offset(_shakeAnimation.value, 0),
                                  child: GestureDetector(
                                    onTap: _triggerEmergency,
                                    child: Container(
                                      width: 200,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 
                                              0.3,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.emergency,
                                        size: 100,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _isEmergencyActive
                            ? 'EMERGENCY ACTIVE'
                            : 'SOS BUTTON',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEmergencyActive
                            ? 'Tap to deactivate emergency'
                            : 'Tap in case of emergency',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.local_police,
                      title: 'Call Police',
                      subtitle: '119',
                      color: Colors.blue,
                      onTap: () async {
                        AnalyticsService.logUserEngagement(
                          'call_police_clicked',
                        );
                        final Uri callUri = Uri.parse('tel:119');
                        if (await canLaunchUrl(callUri)) {
                          await launchUrl(callUri);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.medical_services,
                      title: 'Call Ambulance',
                      subtitle: '1990',
                      color: Colors.red,
                      onTap: () async {
                        AnalyticsService.logUserEngagement(
                          'call_ambulance_clicked',
                        );
                        final Uri callUri = Uri.parse('tel:1990');
                        if (await canLaunchUrl(callUri)) {
                          await launchUrl(callUri);
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.location_on,
                      title: 'Share Location',
                      subtitle: 'Send current location',
                      color: Colors.green,
                      onTap: () async {
                        AnalyticsService.logUserEngagement(
                          'share_location_clicked',
                        );
                        await _getCurrentLocation();
                        if (_currentPosition != null) {
                          final locationUrl =
                              'https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
                          final Uri shareUri = Uri.parse(
                            'sms:?body=${Uri.encodeComponent('My current location: $locationUrl')}',
                          );
                          if (await canLaunchUrl(shareUri)) {
                            await launchUrl(shareUri);
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickActionCard(
                      icon: Icons.contacts,
                      title: 'Emergency Contact',
                      subtitle: _emergencyContact ?? 'Not set',
                      color: Colors.purple,
                      onTap: () {
                        AnalyticsService.logUserEngagement(
                          'emergency_contact_clicked',
                        );
                        // TODO: Navigate to emergency contact settings
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Safety Tips
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Emergency Safety Tips',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSafetyTip(
                        'Stay Calm',
                        'Take deep breaths and assess the situation calmly.',
                        Icons.self_improvement,
                      ),
                      _buildSafetyTip(
                        'Call for Help',
                        'Use the panic button or call emergency services immediately.',
                        Icons.phone,
                      ),
                      _buildSafetyTip(
                        'Share Location',
                        'Let others know your exact location for faster assistance.',
                        Icons.location_on,
                      ),
                      _buildSafetyTip(
                        'Stay Safe',
                        'Move to a safe location if possible and wait for help.',
                        Icons.security,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyTip(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: Colors.blue.shade600, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
