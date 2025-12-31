import 'package:flutter/material.dart';
import 'package:safeguard/screens/contacts_screen.dart';
import 'package:safeguard/screens/fake_call_screen.dart';
import 'package:safeguard/screens/resources_screen.dart';
import 'package:safeguard/screens/about_screen.dart';
import 'package:safeguard/screens/settings_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';
import 'package:safeguard/services/sms_service.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/utils/logger.dart';
import 'package:safeguard/services/location_sharing_service.dart';
import 'package:safeguard/services/settings_service.dart';
import 'package:safeguard/services/contacts_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:safeguard/widgets/bubble_background.dart';
import 'package:safeguard/theme/theme.dart';
import 'package:package_info_plus/package_info_plus.dart'; // New import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _BubbleBackground extends StatefulWidget {
  const _BubbleBackground();

  @override
  State<_BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<_BubbleBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    // Slightly higher opacity in dark themes for visibility
    final double o1 = isDark ? 0.14 : 0.08;
    final double o2 = isDark ? 0.12 : 0.06;
    final double o3 = isDark ? 0.10 : 0.04;
    final Color bubble = scheme.primary.withValues(alpha: o1);
    final Color bubble2 = scheme.secondary.withValues(alpha: o2);
    final Color bubble3 = scheme.onSurface.withValues(alpha: o3);
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BubblePainter(
              t: _controller.value,
              c1: bubble,
              c2: bubble2,
              c3: bubble3,
            ),
          );
        },
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  final double t;
  final Color c1;
  final Color c2;
  final Color c3;

  _BubblePainter({
    required this.t,
    required this.c1,
    required this.c2,
    required this.c3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint p1 = Paint()..color = c1;
    final Paint p2 = Paint()..color = c2;
    final Paint p3 = Paint()..color = c3;

    final double w = size.width;
    final double h = size.height;
    const double twoPi = 6.283185307179586;

    // Six bubbles with varied phases/radii for richness
    final Offset o1 = Offset(
      w * (0.18 + 0.05 * (1 + math.sin(twoPi * (t + 0.10)))),
      h * (0.22 + 0.04 * (1 + math.cos(twoPi * (t + 0.20)))),
    );
    final Offset o2 = Offset(
      w * (0.78 + 0.05 * (1 + math.sin(twoPi * (t + 0.33)))),
      h * (0.28 + 0.05 * (1 + math.cos(twoPi * (t + 0.53)))),
    );
    final Offset o3 = Offset(
      w * (0.52 + 0.06 * (1 + math.sin(twoPi * (t + 0.68)))),
      h * (0.68 + 0.05 * (1 + math.cos(twoPi * (t + 0.82)))),
    );
    final Offset o4 = Offset(
      w * (0.32 + 0.04 * (1 + math.sin(twoPi * (t + 0.25)))),
      h * (0.78 + 0.04 * (1 + math.cos(twoPi * (t + 0.40)))),
    );
    final Offset o5 = Offset(
      w * (0.88 + 0.03 * (1 + math.sin(twoPi * (t + 0.58)))),
      h * (0.58 + 0.03 * (1 + math.cos(twoPi * (t + 0.72)))),
    );
    final Offset o6 = Offset(
      w * (0.08 + 0.03 * (1 + math.sin(twoPi * (t + 0.85)))),
      h * (0.48 + 0.03 * (1 + math.cos(twoPi * (t + 0.95)))),
    );

    canvas.drawCircle(o1, 82, p1);
    canvas.drawCircle(o2, 108, p2);
    canvas.drawCircle(o3, 74, p3);
    canvas.drawCircle(o4, 56, p2);
    canvas.drawCircle(o5, 48, p1);
    canvas.drawCircle(o6, 42, p3);
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.c1 != c1 ||
      oldDelegate.c2 != c2 ||
      oldDelegate.c3 != c3;
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _voiceLoopActive = false;
  bool _voiceDetectionEnabled = false;
  // Removed unused SOS dialog fields
  bool _isInForeground = true;
  // Removed unused Supabase service - using local storage for now
  DateTime? _lastBackPressedAt;
  List<String> _voiceKeywords = const ['help', 'emergency'];
  StreamSubscription? _settingsSubscription;
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  ); // New variable

  @override
  void initState() {
    super.initState();
    _initPackageInfo(); // New call
    WidgetsBinding.instance.addObserver(this);
    _initSpeech();
    _initializeSettings();
    _startRealtimeSettingsSync();
    AnalyticsService.logScreenView('home_screen');
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _initializeSettings() async {
    try {
      // Load initial settings from Supabase
      await _loadVoiceKeywords();
    } catch (e) {
      AppLogger.error('Error initializing settings: $e');
    }
  }

  void _startRealtimeSettingsSync() {
    // Listen for real-time settings changes from Supabase
    _settingsSubscription = SettingsService.listenToSettings().listen(
      (settings) {
        if (mounted) {
          setState(() {
            // Don't auto-enable voice detection from settings sync
            // Only update keywords, user must manually enable via icon button
            // _voiceDetectionEnabled remains as user set it
            _voiceKeywords = settings.voiceKeywords;
          });

          AppLogger.info(
            'Settings synced in real-time: keywords=$_voiceKeywords',
          );

          // Only restart voice loop if user has manually enabled it
          if (_voiceDetectionEnabled && _speechEnabled && _isInForeground) {
            _startVoiceHotwordLoop();
          } else {
            _stopVoiceHotwordLoop();
          }
        }
      },
      onError: (error) {
        AppLogger.error('Error in real-time settings sync: $error');
      },
    );
  }

  Future<void> _loadVoiceKeywords() async {
    try {
      // Load settings from SettingsService
      final settings = await SettingsService.getSettings();

      if (mounted) {
        setState(() {
          // Start with voice detection disabled by default when app opens
          // User must explicitly enable it via the icon button
          _voiceDetectionEnabled = false;
          _voiceKeywords = settings.voiceKeywords;
        });
      }

      AppLogger.info(
        'Voice settings loaded: enabled=$_voiceDetectionEnabled, keywords=$_voiceKeywords',
      );
    } catch (e) {
      AppLogger.error('Error loading voice settings: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopVoiceHotwordLoop();
    _settingsSubscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        // Do not auto-start mic on resume; wait for explicit user action
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isInForeground = false;
        _stopVoiceHotwordLoop();
        break;
    }
  }

  void _initSpeech() async {
    try {
      // Request microphone permission first
      final micPermission = await Permission.microphone.request();

      if (!micPermission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required for voice recognition',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        _speechEnabled = false;
        setState(() {});
        return;
      }

      // Initialize speech recognition
      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          AppLogger.error('Speech recognition error: $error');
        },
        onStatus: (status) {
          AppLogger.info('Speech status: $status');
        },
      );

      if (_speechEnabled) {
        AppLogger.info('Speech recognition initialized successfully');
      } else {
        AppLogger.warning('Failed to initialize speech recognition');
      }

      setState(() {});
    } catch (e) {
      AppLogger.error('Error initializing speech: $e');
      _speechEnabled = false;
      setState(() {});
    }
  }

  Future<void> _startListening() async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          final text = result.recognizedWords.toLowerCase();
          final matched = _voiceKeywords.any((w) => text.contains(w));
          if (result.finalResult && matched) {
            _speechToText.stop();
            _sendSOS();
          }
        },
        listenFor: const Duration(seconds: 8),
        listenOptions: SpeechListenOptions(partialResults: false),
      );
    }
  }

  void _stopVoiceHotwordLoop() {
    _voiceLoopActive = false;
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    _speechToText.statusListener = null;
  }

  Future<void> _sendSOS() async {
    HapticFeedback.heavyImpact();
    if (!mounted) return;

    // Log SOS trigger
    AnalyticsService.logSosTriggered('manual_button');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Sending SOS...'),
            ],
          ),
        );
      },
    );

    try {
      // Load contacts from local storage (with Supabase fallback)
      await ContactsService.initialize();
      final emergencyContacts =
          await ContactsService.getEmergencyPhoneNumbers();

      if (emergencyContacts.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No emergency contacts found. Please add a contact first.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check and request location permission
      Position? position;
      try {
        // Check permission status
        LocationPermission permission = await Geolocator.checkPermission();

        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            AppLogger.warning('Location permission denied');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Location permission denied. Please enable it in app settings.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 3),
                ),
              );
            }
            throw Exception('Location permission denied');
          }
        }

        if (permission == LocationPermission.deniedForever) {
          AppLogger.warning('Location permission denied forever');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission was permanently denied. Please enable in device settings.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
          }
          throw Exception(
            'Location permission permanently denied. Please enable in settings.',
          );
        }

        // Check if location services are enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          AppLogger.warning('Location services disabled');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location services are disabled. Please enable GPS in your device settings.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          throw Exception('Location services are disabled. Please enable GPS.');
        }

        // Get current position
        AppLogger.info('Fetching current location...');
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );

        AppLogger.info(
          'Location obtained: ${position.latitude}, ${position.longitude}',
        );
      } catch (e) {
        AppLogger.error('Error getting location: $e');

        // Show error but don't stop SOS
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location unavailable: $e'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        position = null;
      }

      // Prepare SOS message
      String sosMessage;

      if (position != null) {
        AppLogger.info(
          'Position available: ${position.latitude}, ${position.longitude}',
        );

        // Include Google Maps link
        final mapsUrl = LocationSharingService.getGoogleMapsUrl(
          position.latitude,
          position.longitude,
        );

        sosMessage =
            '''🚨 EMERGENCY SOS 🚨

I need help!

📍 My location:
$mapsUrl

🕐 ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}

Please call me!''';

        AppLogger.info('SOS message prepared with location');
      } else {
        // No location available - send basic SOS
        AppLogger.warning('No location available for SOS');
        sosMessage =
            '''🚨 EMERGENCY SOS 🚨

I need help!

🕐 ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}

Location unavailable. Please call me!''';
      }

      // Request SMS permission
      final smsPermission = await SmsService.requestSmsPermission();
      if (!smsPermission) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS permission is required to send SOS.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Send SMS to all emergency contacts
      bool anySuccess = false;
      for (final phone in emergencyContacts) {
        final sent = await SmsService.sendSms(phone, sosMessage);
        anySuccess = anySuccess || sent;
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            anySuccess
                ? 'SOS sent to ${emergencyContacts.length} contact(s) with location!'
                : 'Failed to send SOS',
          ),
          backgroundColor: anySuccess ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending SOS: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendQuickMessage(String message) async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Preparing message...'),
            ],
          ),
        );
      },
    );

    try {
      // Load contacts from local storage (with Supabase fallback)
      await ContactsService.initialize();
      final emergencyContacts =
          await ContactsService.getEmergencyPhoneNumbers();

      if (emergencyContacts.isEmpty) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No emergency contacts found. Please add one.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final smsPermission = await SmsService.requestSmsPermission();
      if (!smsPermission) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('SMS permission is required to send message.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      bool anySuccess = false;
      for (final phone in emergencyContacts) {
        final sent = await SmsService.sendSms(phone, message);
        anySuccess = anySuccess || sent;
        await Future.delayed(const Duration(milliseconds: 120));
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            anySuccess
                ? 'Message ready to send to ${emergencyContacts.length} contact(s)'
                : 'Failed to open SMS app',
          ),
          backgroundColor: anySuccess ? Colors.green : Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending message: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Removed unused _showSosConfirmationDialog

  void _startVoiceHotwordLoop() {
    if (_voiceLoopActive) return;
    if (!_isInForeground) return;
    if (!_voiceDetectionEnabled) return;
    if (!_speechEnabled) return;

    _voiceLoopActive = true;
    _speechToText.statusListener = (status) async {
      if (!_voiceLoopActive) return;
      if (!mounted) return;

      if (status == 'notListening' &&
          _voiceDetectionEnabled &&
          _isInForeground) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted &&
            _isInForeground &&
            !_speechToText.isListening &&
            _voiceLoopActive) {
          _startListening();
        }
      }
    };

    if (_isInForeground && !_speechToText.isListening) {
      _startListening();
    }
  }

  void _onItemTapped(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    });

    // Log navigation
    final List<String> screenNames = [
      'home',
      'contacts',
      'fake_call',
      'resources',
      'about',
    ];
    if (index < screenNames.length) {
      AnalyticsService.logScreenView('${screenNames[index]}_screen');
    }
  }

  // Removed legacy RTDB demo methods

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
            _pageController.jumpToPage(0);
          });
          return;
        }

        final now = DateTime.now();
        if (_lastBackPressedAt == null ||
            now.difference(_lastBackPressedAt!) > const Duration(seconds: 2)) {
          _lastBackPressedAt = now;
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Press back again to exit')),
            );
          }
          return;
        }
        // Don't pop - let user press back again
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SafeGuard'),
          actions: [
            IconButton(
              tooltip: _voiceDetectionEnabled
                  ? 'Disable voice trigger'
                  : 'Enable voice trigger',
              icon: Icon(
                (_voiceDetectionEnabled && _speechEnabled && _speechToText.isListening)
                    ? Icons.mic
                    : Icons.mic_off,
              ),
              onPressed: () async {
                setState(() {
                  _voiceDetectionEnabled = !_voiceDetectionEnabled;
                });

                // Save voice detection state
                await SettingsService.updateVoiceDetection(
                  _voiceDetectionEnabled,
                );

                if (_voiceDetectionEnabled && _speechEnabled) {
                  _startVoiceHotwordLoop();
                } else {
                  _stopVoiceHotwordLoop();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const SettingsScreen(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(
                            opacity: animation.drive(
                              CurveTween(curve: Curves.easeInOut),
                            ),
                            child: child,
                          );
                        },
                    transitionDuration: const Duration(milliseconds: 250),
                  ),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'lib/logoSafeguard.jpg',
                      height: 60,
                      width: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'SafeGuard',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Version: ${_packageInfo.version}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Developed by Jerusha\'s Tech',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onPrimary.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home),
                title: Text(
                  'Home',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _onItemTapped(0); // Navigate to Home
                },
              ),
              ListTile(
                leading: const Icon(Icons.contacts),
                title: Text(
                  'Contacts',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _onItemTapped(1); // Navigate to Contacts
                },
              ),
              ListTile(
                leading: const Icon(Icons.call),
                title: Text(
                  'Fake Call',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _onItemTapped(2); // Navigate to Fake Call
                },
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: Text(
                  'Resources',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _onItemTapped(3); // Navigate to Resources
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: Text(
                  'About',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  _onItemTapped(4); // Navigate to About
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(
                  'Settings',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  Navigator.pop(context); // Close the drawer
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SettingsScreen(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                            return FadeTransition(
                              opacity: animation.drive(
                                CurveTween(curve: Curves.easeInOut),
                              ),
                              child: child,
                            );
                          },
                      transitionDuration: const Duration(milliseconds: 250),
                    ),
                  );
                },
              ),
              const Divider(), // Separator for theme options
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Themes',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.color_lens_outlined),
                title: Text(
                  'Red Theme',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  ThemeController.instance.setVariant(ThemeVariant.redDark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens),
                title: Text(
                  'Black Theme',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  ThemeController.instance.setVariant(ThemeVariant.blackDark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.color_lens_sharp),
                title: Text(
                  'White Theme',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                onTap: () {
                  ThemeController.instance.setVariant(ThemeVariant.whiteLight);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            const Positioned.fill(child: BubbleBackground()),
            Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: <Widget>[
                      HomeScreenBody(
                        onSosPressed: _sendSOS,
                        onQuickMessage: _sendQuickMessage,
                      ),
                      const ContactsScreen(),
                      const FakeCallScreen(),
                      const ResourcesScreen(),
                      const AboutScreen(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Stack(
          children: [
            BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.contacts),
                  label: 'Contacts',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.call),
                  label: 'Fake Call',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.article),
                  label: 'Resources',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: 'About',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              onTap: _onItemTapped,
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: _selectedIndex * (MediaQuery.of(context).size.width / 5),
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width / 5,
                height: 4, // Height of the indicator
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreenBody extends StatefulWidget {
  final VoidCallback onSosPressed;
  final Future<void> Function(String message) onQuickMessage;

  const HomeScreenBody({
    super.key,
    required this.onSosPressed,
    required this.onQuickMessage,
  });

  @override
  State<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  String _helpMsg = 'Help me!';
  String _noSignalMsg = 'No signal. I might be offline.';
  String _comingMsg = "I'm coming";
  StreamSubscription? _settingsStreamSubscription;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
      lowerBound: 0.0,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _loadQuickMessages();
    _startRealtimeQuickMessagesSync();
  }

  Future<void> _loadQuickMessages() async {
    try {
      final help = await SettingsService.getQuickMsgHelp();
      final noSignal = await SettingsService.getQuickMsgNoSignal();
      final coming = await SettingsService.getQuickMsgComing();

      if (mounted) {
        setState(() {
          _helpMsg = help;
          _noSignalMsg = noSignal;
          _comingMsg = coming;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading quick messages: $e');
    }
  }

  void _startRealtimeQuickMessagesSync() {
    // Listen for real-time changes to quick messages
    _settingsStreamSubscription = SettingsService.listenToSettings().listen(
      (settings) async {
        // When settings change, reload quick messages
        await _loadQuickMessages();
      },
      onError: (error) {
        AppLogger.error('Error in quick messages real-time sync: $error');
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _settingsStreamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          FadeTransition(
            opacity: Tween<double>(begin: 0.65, end: 1.0).animate(
              CurvedAnimation(
                parent: _pulseController,
                curve: Curves.easeInOut,
              ),
            ),
            child: Text(
              'Press the button in case of emergency',
              style: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.04).animate(
              CurvedAnimation(
                parent: _pulseController,
                curve: Curves.easeInOut,
              ),
            ),
            child: ElevatedButton(
              onPressed: widget.onSosPressed,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(50),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shadowColor: Theme.of(context).colorScheme.primary,
                elevation: 12,
              ),
              child: Icon(
                Icons.sos,
                size: 100,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onQuickMessage(_helpMsg),
                    child: Text(_helpMsg),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onQuickMessage(_noSignalMsg),
                    child: Text(_noSignalMsg),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => widget.onQuickMessage(_comingMsg),
                    child: Text(_comingMsg),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
