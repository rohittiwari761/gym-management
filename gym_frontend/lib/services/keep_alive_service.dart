import 'dart:async';
import 'package:flutter/foundation.dart';
import '../security/secure_http_client.dart';
import '../security/security_config.dart';

class KeepAliveService {
  static final KeepAliveService _instance = KeepAliveService._internal();
  factory KeepAliveService() => _instance;
  KeepAliveService._internal();

  Timer? _keepAliveTimer;
  final SecureHttpClient _httpClient = SecureHttpClient();
  bool _isRunning = false;
  DateTime? _lastPingTime;
  int _consecutiveFailures = 0;
  int _totalPings = 0;
  int _successfulPings = 0;

  /// Duration between keep-alive pings (Railway sleeps after ~30 minutes of inactivity)
  static const Duration _pingInterval = Duration(minutes: 20); // Ping every 20 minutes
  static const Duration _aggressivePingInterval = Duration(minutes: 10); // Reduced aggressive ping
  
  /// Maximum consecutive failures before stopping
  static const int _maxConsecutiveFailures = 10;

  /// Initialize and start the keep-alive service
  void initialize() {
    if (_isRunning) {
      // Service already running
      return;
    }

    // Initializing keep-alive service with ${_pingInterval.inMinutes} minute intervals
    
    _isRunning = true;
    _consecutiveFailures = 0;
    _totalPings = 0;
    _successfulPings = 0;
    
    // Start the periodic timer
    _keepAliveTimer = Timer.periodic(_pingInterval, (timer) {
      _performKeepAlivePing();
    });

    // Delay initial ping to avoid rate limiting on startup
    Timer(const Duration(minutes: 1), () {
      _performKeepAlivePing();
    });

    // Keep-alive service started successfully
  }

  /// Stop the keep-alive service
  void stop() {
    if (!_isRunning) {
      // Service already stopped
      return;
    }

    // Stopping keep-alive service
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
    _isRunning = false;
    
    // Keep-alive service stopped
    _logStatistics();
  }

  /// Perform a lightweight ping to keep the server awake
  Future<void> _performKeepAlivePing() async {
    if (!_isRunning) return;

    try {
      // Starting ping #${_totalPings + 1}
      _totalPings++;
      _lastPingTime = DateTime.now();

      // Use a lightweight endpoint that doesn't require authentication
      // This could be a health check endpoint or a simple ping endpoint
      final response = await _httpClient.get(
        'health/', // Health check endpoint
        requireAuth: false,
      ).timeout(const Duration(seconds: 10));

      if (response.isSuccess) {
        // If this was a recovery from failures, switch back to normal mode
        if (_consecutiveFailures >= 2) {
          // Server recovered! Switching back to normal mode
          _switchToNormalMode();
        }
        
        _consecutiveFailures = 0;
        _successfulPings++;
        // Ping successful (${response.statusCode}) - server is awake and responsive
      } else {
        _handlePingFailure('HTTP ${response.statusCode}: ${response.errorMessage}');
      }

    } catch (e) {
      _handlePingFailure(e.toString());
    }

    _logStatistics();
  }

  /// Handle ping failure
  void _handlePingFailure(String error) {
    _consecutiveFailures++;
    if (kDebugMode) {
      print('KEEP_ALIVE: Ping failed (attempt ${_consecutiveFailures}/$_maxConsecutiveFailures): $error');
    }

    // Switch to aggressive pinging when server appears to be down
    if (_consecutiveFailures >= 2) {
      // Server appears to be sleeping, switching to aggressive mode
      _switchToAggressiveMode();
    }

    // If we have too many consecutive failures, try alternative endpoints
    if (_consecutiveFailures >= 3) {
      // Multiple failures detected, switching to longer intervals to avoid rate limiting
      // Disabled aggressive wake-up strategies to prevent rate limiting
    }

    // Stop service if we exceed max failures
    if (_consecutiveFailures >= _maxConsecutiveFailures) {
      if (kDebugMode) {
        print('KEEP_ALIVE: Max consecutive failures reached, stopping service');
      }
      stop();
    }
  }

  /// Switch to aggressive ping mode when server is down
  void _switchToAggressiveMode() {
    _keepAliveTimer?.cancel();
    
    // Switching to aggressive mode (${_aggressivePingInterval.inMinutes} min intervals)
    
    _keepAliveTimer = Timer.periodic(_aggressivePingInterval, (timer) {
      _performKeepAlivePing();
    });
  }

  /// Switch back to normal ping mode when server is responsive
  void _switchToNormalMode() {
    _keepAliveTimer?.cancel();
    
    // Switching back to normal mode (${_pingInterval.inMinutes} min intervals)
    
    _keepAliveTimer = Timer.periodic(_pingInterval, (timer) {
      _performKeepAlivePing();
    });
  }

  /// Try multiple wake-up strategies when server appears to be sleeping
  Future<void> _tryWakeUpStrategies() async {
    // Attempting to wake up sleeping server...
    
    // Strategy 1: Try multiple health endpoints rapidly
    await _tryRapidHealthChecks();
    
    // Strategy 2: Try different endpoints
    await _tryAlternativeEndpoints();
    
    // Strategy 3: Try authenticated endpoints (might wake up more services)
    await _tryAuthenticatedEndpoints();
  }

  /// Try rapid health checks to wake up the server
  Future<void> _tryRapidHealthChecks() async {
    // Strategy 1 - Rapid health checks
    
    for (int i = 0; i < 3; i++) {
      try {
        final response = await _httpClient.get(
          'health/',
          requireAuth: false,
        ).timeout(const Duration(seconds: 15)); // Longer timeout for sleeping server

        if (response.isSuccess) {
          // Rapid health check successful on attempt ${i + 1}
          _consecutiveFailures = 0;
          _successfulPings++;
          _switchToNormalMode(); // Switch back to normal mode
          return;
        }
      } catch (e) {
        // Rapid health check ${i + 1}/3 failed
        if (i < 2) await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Try alternative endpoints when main health check fails
  Future<void> _tryAlternativeEndpoints() async {
    // Strategy 2 - Alternative endpoints
    
    final endpoints = [
      'ping/',
      'status/',
      'health/',
      '', // Root endpoint  
    ];

    for (final endpoint in endpoints) {
      try {
        // Trying alternative endpoint: $endpoint
        
        final response = await _httpClient.get(
          endpoint,
          requireAuth: false,
        ).timeout(const Duration(seconds: 15));

        if (response.isSuccess) {
          // Alternative endpoint successful: $endpoint
          _consecutiveFailures = 0;
          _successfulPings++;
          _switchToNormalMode(); // Switch back to normal mode
          return;
        }
      } catch (e) {
        // Alternative endpoint failed: $endpoint
        continue;
      }
    }

    // All alternative endpoints failed
  }

  /// Try authenticated endpoints as a last resort
  Future<void> _tryAuthenticatedEndpoints() async {
    // Strategy 3 - Authenticated endpoints
    
    final endpoints = [
      'auth/check/',
      'users/profile/',
      'members/?limit=1',
    ];

    for (final endpoint in endpoints) {
      try {
        // Trying authenticated endpoint: $endpoint
        
        final response = await _httpClient.get(
          endpoint,
          requireAuth: true,
        ).timeout(const Duration(seconds: 15));

        if (response.isSuccess) {
          // Authenticated endpoint successful: $endpoint
          _consecutiveFailures = 0;
          _successfulPings++;
          _switchToNormalMode(); // Switch back to normal mode
          return;
        }
      } catch (e) {
        // Authenticated endpoint failed: $endpoint
        continue;
      }
    }

    // All authenticated endpoints failed
  }

  /// Log service statistics
  void _logStatistics() {
    final successRate = _totalPings > 0 ? (_successfulPings / _totalPings * 100).toStringAsFixed(1) : '0.0';
    
    if (kDebugMode) {
      print('KEEP_ALIVE Statistics:');
      print('  Total pings: $_totalPings');
      print('  Successful: $_successfulPings');
      print('  Success rate: $successRate%');
      print('  Consecutive failures: $_consecutiveFailures');
      
      if (_lastPingTime != null) {
        final timeSinceLastPing = DateTime.now().difference(_lastPingTime!);
        print('  Last ping: ${timeSinceLastPing.inMinutes} minutes ago');
      }
    }
  }

  /// Get service status
  Map<String, dynamic> getStatus() {
    final successRate = _totalPings > 0 ? (_successfulPings / _totalPings * 100) : 0.0;
    
    return {
      'isRunning': _isRunning,
      'totalPings': _totalPings,
      'successfulPings': _successfulPings,
      'successRate': successRate,
      'consecutiveFailures': _consecutiveFailures,
      'lastPingTime': _lastPingTime?.toIso8601String(),
      'nextPingIn': _isRunning && _lastPingTime != null 
          ? _pingInterval.inMinutes - DateTime.now().difference(_lastPingTime!).inMinutes
          : null,
    };
  }

  /// Manually trigger a ping (useful for testing)
  Future<bool> pingNow() async {
    if (!_isRunning) {
      // Service not running, starting it first
      initialize();
    }

    // Manual ping triggered
    
    // First try a regular ping
    await _performKeepAlivePing();
    
    // Disabled aggressive wake-up strategies to prevent rate limiting
    // Simple failure handling without multiple rapid requests
    
    return _consecutiveFailures == 0;
  }

  /// Check if the service should be running (only when app is active)
  bool get shouldBeRunning => _isRunning;

  /// Restart the service with fresh settings
  void restart() {
    // Restarting keep-alive service
    stop();
    
    // Wait a moment before restarting
    Timer(const Duration(seconds: 2), () {
      initialize();
    });
  }

  /// Dispose of resources
  void dispose() {
    // Disposing keep-alive service
    stop();
  }
}

/// Extension to add keep-alive functionality to SecureHttpClient
extension KeepAliveExtension on SecureHttpClient {
  /// Make a keep-alive ping request
  Future<bool> keepAlivePing() async {
    try {
      final response = await get('health/', requireAuth: false);
      return response.isSuccess;
    } catch (e) {
      if (kDebugMode) {
        print('KEEP_ALIVE_EXT: Ping failed: $e');
      }
      return false;
    }
  }
}