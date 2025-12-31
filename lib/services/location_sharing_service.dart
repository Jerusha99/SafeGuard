import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:safeguard/utils/logger.dart';
import 'package:safeguard/services/supabase_service.dart';
import 'package:safeguard/services/device_id_service.dart';

class LocationSharingService {
  static final SupabaseService _supabaseService = SupabaseService();
  static Timer? _locationUpdateTimer;
  static String? _activeSessionId;
  
  /// Start real-time location sharing session
  static Future<String?> startLocationSharingSession({
    required List<String> recipientPhones,
    String? customMessage,
  }) async {
    try {
      final deviceId = await DeviceIdService.getOrCreateDeviceId();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 4));
      
      // Generate unique session ID
      final sessionId = _generateUniqueId();
      
      // Create location sharing session in Supabase
      final sessionData = {
        'id': sessionId,
        'device_id': deviceId,
        'created_at': now.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'is_active': true,
        'message': customMessage ?? 'Emergency location shared',
      };
      
      await _supabaseService.writeData('location_sharing_sessions', sessionData);
      
      // Store recipient mappings
      for (final phone in recipientPhones) {
        await _supabaseService.writeData('shared_locations', {
          'session_id': sessionId,
          'recipient_phone': phone,
          'sent_at': now.toIso8601String(),
        });
      }
      
      _activeSessionId = sessionId;
      
      // Start periodic location updates
      _startPeriodicLocationUpdates(sessionId, deviceId);
      
      final shareableLink = _generateShareableLink(sessionId);
      AppLogger.info('Location sharing session started: $sessionId');
      return shareableLink;
      
    } catch (e) {
      AppLogger.error('Error starting location sharing session: $e');
      return null;
    }
  }
  
  /// Start periodic location updates
  static void _startPeriodicLocationUpdates(String sessionId, String deviceId) {
    _locationUpdateTimer?.cancel();
    
    // Update location every 10 seconds
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        try {
          // Check if session is still valid
          final isValid = await isSessionValid(sessionId);
          if (!isValid) {
            AppLogger.info('Session expired, stopping location updates: $sessionId');
            timer.cancel();
            _locationUpdateTimer = null;
            _activeSessionId = null;
            return;
          }
          
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );
          
          // Update live location in Supabase
          await _supabaseService.writeData('live_locations', {
            'session_id': sessionId,
            'device_id': deviceId,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
            'is_active': true,
          });
          
          AppLogger.info('Location updated for session: $sessionId');
        } catch (e) {
          AppLogger.error('Error updating location: $e');
        }
      },
    );
    
    // Schedule automatic session expiry after 4 hours
    Future.delayed(const Duration(hours: 4), () async {
      if (_activeSessionId == sessionId) {
        AppLogger.info('Session reached 4-hour limit, stopping: $sessionId');
        await stopLocationSharingSession();
      }
    });
  }
  
  /// Stop location sharing session
  static Future<void> stopLocationSharingSession() async {
    try {
      _locationUpdateTimer?.cancel();
      _locationUpdateTimer = null;
      
      if (_activeSessionId != null) {
        // Mark session as inactive
        final sessions = await _supabaseService.readDataOnce(
          'location_sharing_sessions',
        );
        
        for (final session in sessions) {
          if (session['id'] == _activeSessionId) {
            await _supabaseService.updateData(
              'location_sharing_sessions',
              _activeSessionId!,
              {'is_active': false},
            );
            break;
          }
        }
        
        AppLogger.info('Location sharing session stopped: $_activeSessionId');
        _activeSessionId = null;
      }
    } catch (e) {
      AppLogger.error('Error stopping location sharing: $e');
    }
  }
  
  /// Listen to real-time location updates for a session
  static Stream<Map<String, dynamic>> listenToLocationUpdates(String sessionId) {
    return _supabaseService
        .listenForUpdates('live_locations')
        .map((locations) {
      final sessionLocation = locations.firstWhere(
        (loc) => loc['session_id'] == sessionId && loc['is_active'] == true,
        orElse: () => <String, dynamic>{},
      );
      return sessionLocation;
    });
  }
  
  /// Get current location and start sharing
  static Future<String?> getCurrentLocationAndStartSharing({
    required List<String> recipientPhones,
    String? customMessage,
  }) async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission permanently denied');
      }
      
      // Start location sharing session
      return await startLocationSharingSession(
        recipientPhones: recipientPhones,
        customMessage: customMessage,
      );
      
    } catch (e) {
      AppLogger.error('Error getting current location and starting sharing: $e');
      return null;
    }
  }
  
  /// Check if a session is still valid (not expired)
  static Future<bool> isSessionValid(String sessionId) async {
    try {
      final sessions = await _supabaseService.readDataOnce(
        'location_sharing_sessions',
      );
      
      final session = sessions.firstWhere(
        (s) => s['id'] == sessionId,
        orElse: () => <String, dynamic>{},
      );
      
      if (session.isEmpty) return false;
      
      final expiresAt = DateTime.parse(session['expires_at']);
      final now = DateTime.now();
      
      return now.isBefore(expiresAt) && session['is_active'] == true;
      
    } catch (e) {
      AppLogger.error('Error checking session validity: $e');
      return false;
    }
  }
  
  /// Get session data from session ID
  static Future<Map<String, dynamic>?> getSessionData(String sessionId) async {
    try {
      final sessions = await _supabaseService.readDataOnce(
        'location_sharing_sessions',
      );
      
      final session = sessions.firstWhere(
        (s) => s['id'] == sessionId,
        orElse: () => <String, dynamic>{},
      );
      
      if (session.isEmpty) return null;
      
      // Check if session is still valid
      final isValid = await isSessionValid(sessionId);
      if (!isValid) {
        AppLogger.warning('Session expired: $sessionId');
        return null;
      }
      
      return session;
      
    } catch (e) {
      AppLogger.error('Error getting session data: $e');
      return null;
    }
  }
  
  /// Clean up expired sessions
  static Future<void> cleanupExpiredSessions() async {
    try {
      final sessions = await _supabaseService.readDataOnce(
        'location_sharing_sessions',
      );
      
      final now = DateTime.now();
      
      for (final session in sessions) {
        final expiresAt = DateTime.parse(session['expires_at']);
        
        if (now.isAfter(expiresAt)) {
          await _supabaseService.updateData(
            'location_sharing_sessions',
            session['id'],
            {'is_active': false},
          );
          AppLogger.info('Cleaned up expired session: ${session['id']}');
        }
      }
      
      AppLogger.info('Expired sessions cleanup completed');
      
    } catch (e) {
      AppLogger.error('Error cleaning up expired sessions: $e');
    }
  }
  
  /// Generate a unique ID for the session
  static String _generateUniqueId() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return String.fromCharCodes(
      Iterable.generate(24, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
  
  /// Generate a shareable link
  static String _generateShareableLink(String sessionId) {
    // In production, this would be your domain
    return 'https://safeguard.app/track/$sessionId';
  }
  
  /// Get Google Maps URL for location
  static String getGoogleMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }
  
  /// Get Apple Maps URL for location
  static String getAppleMapsUrl(double latitude, double longitude) {
    return 'https://maps.apple.com/?q=$latitude,$longitude';
  }
  
  /// Format location message for SMS with session link
  static String formatLocationMessage({
    required String sessionLink,
    required String customMessage,
    double? latitude,
    double? longitude,
  }) {
    final buffer = StringBuffer();
    buffer.writeln(customMessage);
    buffer.writeln();
    buffer.writeln('📍 Track my live location:');
    buffer.writeln(sessionLink);
    
    if (latitude != null && longitude != null) {
      buffer.writeln();
      buffer.writeln('Current location: ${getGoogleMapsUrl(latitude, longitude)}');
    }
    
    buffer.writeln();
    buffer.writeln('⏰ Real-time updates for 4 hours');
    buffer.writeln('🕐 Started at: ${DateTime.now().toLocal().toString()}');
    
    return buffer.toString();
  }
}
