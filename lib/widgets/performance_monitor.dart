import 'package:flutter/material.dart';
import 'package:safeguard/services/analytics_service.dart';
import 'package:safeguard/services/connectivity_service.dart';
import 'dart:async';

class PerformanceMonitor extends StatefulWidget {
  const PerformanceMonitor({super.key});

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final ConnectivityService _connectivityService = ConnectivityService();
  Timer? _performanceTimer;
  int _frameCount = 0;
  double _fps = 0.0;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _startPerformanceMonitoring();
    _monitorConnectivity();
  }

  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _fps = _frameCount.toDouble();
          _frameCount = 0;
        });
        
        // Log performance metrics
        AnalyticsService.logAppPerformance('fps', _fps.round());
      }
    });
  }

  void _monitorConnectivity() {
    _connectivityService.connectivityStream.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOnline = isOnline;
        });
      }
    });
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'FPS: ${_fps.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              color: _isOnline ? Colors.green : Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
