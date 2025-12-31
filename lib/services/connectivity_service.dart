import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:safeguard/utils/logger.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  ConnectivityResult _currentStatus = ConnectivityResult.none;
  bool _isOnline = false;
  
  // Getters
  ConnectivityResult get currentStatus => _currentStatus;
  bool get isOnline => _isOnline;
  
  // Stream controllers for listening to connectivity changes
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<void> initialize() async {
    try {
      // Get initial connectivity status
      final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
      
      // Listen to connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectivityStatus,
        onError: (error) {
          AppLogger.error('Connectivity error: $error');
        },
      );
      
      AppLogger.info('Connectivity service initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize connectivity service: $e');
    }
  }

  void _updateConnectivityStatus(List<ConnectivityResult> result) {
    _currentStatus = result.isNotEmpty ? result.first : ConnectivityResult.none;
    _isOnline = _currentStatus != ConnectivityResult.none;
    
    AppLogger.info('Connectivity status changed: $_currentStatus, Online: $_isOnline');
    _connectivityController.add(_isOnline);
  }

  Future<bool> checkConnectivity() async {
    try {
      final List<ConnectivityResult> result = await _connectivity.checkConnectivity();
      _updateConnectivityStatus(result);
      return _isOnline;
    } catch (e) {
      AppLogger.error('Failed to check connectivity: $e');
      return false;
    }
  }

  Future<bool> isConnectedToInternet() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result.isNotEmpty && result.first != ConnectivityResult.none;
    } catch (e) {
      AppLogger.error('Failed to check internet connection: $e');
      return false;
    }
  }

  String getConnectionTypeString() {
    switch (_currentStatus) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'No Connection';
    }
  }

  bool isWifiConnected() {
    return _currentStatus == ConnectivityResult.wifi;
  }

  bool isMobileDataConnected() {
    return _currentStatus == ConnectivityResult.mobile;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}
