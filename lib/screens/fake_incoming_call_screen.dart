
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:vibration/vibration.dart';
import 'package:safeguard/services/analytics_service.dart';

class FakeIncomingCallScreen extends StatefulWidget {
  final String contactName;
  final String phoneNumber;
  final int callDuration;
  final bool enableVibration;
  final bool enableSound;
  final String ringtone;

  const FakeIncomingCallScreen({
    super.key,
    required this.contactName,
    required this.phoneNumber,
    required this.callDuration,
    required this.enableVibration,
    required this.enableSound,
    required this.ringtone,
  });

  @override
  State<FakeIncomingCallScreen> createState() => _FakeIncomingCallScreenState();
}

class _FakeIncomingCallScreenState extends State<FakeIncomingCallScreen>
    with TickerProviderStateMixin {
  Timer? _vibrateTimer;
  Timer? _callTimer;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isCallActive = false;
  int _callTimeRemaining = 0;
  
  @override
  void initState() {
    super.initState();
    _callTimeRemaining = widget.callDuration;
    _initializeAnimations();
    _startVibration();
    _startCallTimer();
    AnalyticsService.logCustomEvent('fake_call_started', {
      'contact_name': widget.contactName,
      'call_duration': widget.callDuration,
      'ringtone': widget.ringtone,
    });
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _pulseController.repeat(reverse: true);
    _slideController.forward();
  }
  
  @override
  void dispose() {
    _stopVibration();
    _callTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
  
  void _startVibration() async {
    if (widget.enableVibration && await Vibration.hasVibrator()) {
      _vibrateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!_isCallActive) {
          Vibration.vibrate(pattern: [500, 1000, 500, 1000]);
        }
      });
    }
  }
  
  void _stopVibration() {
    _vibrateTimer?.cancel();
    Vibration.cancel();
  }

  void _startCallTimer() {
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callTimeRemaining > 0) {
        setState(() {
          _callTimeRemaining--;
        });
      } else {
        _endCall();
      }
    });
  }

  void _answerCall() {
    setState(() {
      _isCallActive = true;
    });
    _stopVibration();
    HapticFeedback.mediumImpact();
    AnalyticsService.logCustomEvent('fake_call_answered', {
      'contact_name': widget.contactName,
    });
  }

  void _declineCall() {
    _endCall();
    AnalyticsService.logCustomEvent('fake_call_declined', {
      'contact_name': widget.contactName,
    });
  }

  void _endCall() {
    _callTimer?.cancel();
    _stopVibration();
    AnalyticsService.logCustomEvent('fake_call_ended', {
      'contact_name': widget.contactName,
      'call_duration': widget.callDuration - _callTimeRemaining,
    });
    Navigator.of(context).pop();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isCallActive 
                ? [Colors.green.shade900, Colors.green.shade700, Colors.black]
                : [Colors.blue.shade900, Colors.blue.shade700, Colors.black],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Status Bar
                if (_isCallActive) ...[
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Call in progress',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatTime(_callTimeRemaining),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Contact Avatar
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isCallActive ? 1.0 : _pulseAnimation.value,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Contact Name
                Text(
                  widget.contactName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Phone Number
                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 18,
                  ),
                ),
                
                if (!_isCallActive) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Incoming Call',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Call Controls
                if (_isCallActive) ...[
                  // Active Call Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Mute Button
                        _buildCallControlButton(
                          icon: Icons.mic_off,
                          label: 'Mute',
                          color: Colors.grey,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                          },
                        ),
                        
                        // Speaker Button
                        _buildCallControlButton(
                          icon: Icons.volume_up,
                          label: 'Speaker',
                          color: Colors.grey,
                          onPressed: () {
                            HapticFeedback.lightImpact();
                          },
                        ),
                        
                        // End Call Button
                        _buildCallControlButton(
                          icon: Icons.call_end,
                          label: 'End',
                          color: Colors.red,
                          onPressed: _endCall,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Incoming Call Controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Decline Button
                        _buildCallControlButton(
                          icon: Icons.call_end,
                          label: 'Decline',
                          color: Colors.red,
                          onPressed: _declineCall,
                        ),
                        
                        // Answer Button
                        _buildCallControlButton(
                          icon: Icons.call,
                          label: 'Answer',
                          color: Colors.green,
                          onPressed: _answerCall,
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCallControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 30),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
