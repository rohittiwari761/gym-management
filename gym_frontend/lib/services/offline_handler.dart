import 'dart:io';
import 'package:flutter/material.dart';
import '../security/security_config.dart';

class OfflineHandler {
  static bool _isOffline = false;
  static DateTime? _lastConnectionAttempt;
  static const Duration _retryInterval = Duration(seconds: 30);

  /// Check if the app is currently in offline mode
  static bool get isOffline => _isOffline;

  /// Handle network errors gracefully
  static Map<String, dynamic> handleNetworkError(dynamic error) {
    final errorString = error.toString();
    
    // Mark as offline if we detect network issues
    if (errorString.contains('SocketException') ||
        errorString.contains('Connection refused') ||
        errorString.contains('Network is unreachable')) {
      _markOffline();
    }

    SecurityConfig.logSecurityEvent('NETWORK_ERROR', {
      'error': errorString,
      'isOffline': _isOffline,
    });

    return {
      'success': false,
      'isNetworkError': true,
      'message': _isOffline 
          ? 'You appear to be offline. Please check your internet connection.'
          : 'Network connection failed. Please try again.',
    };
  }

  /// Mark the app as offline
  static void _markOffline() {
    _isOffline = true;
    _lastConnectionAttempt = DateTime.now();
  }

  /// Attempt to reconnect
  static Future<bool> attemptReconnection() async {
    if (_lastConnectionAttempt != null &&
        DateTime.now().difference(_lastConnectionAttempt!) < _retryInterval) {
      return false; // Too soon to retry
    }

    try {
      // Simple connectivity test
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _isOffline = false;
        SecurityConfig.logSecurityEvent('RECONNECTION_SUCCESS', {});
        return true;
      }
    } catch (e) {
      _lastConnectionAttempt = DateTime.now();
      SecurityConfig.logSecurityEvent('RECONNECTION_FAILED', {
        'error': e.toString(),
      });
    }
    
    return false;
  }

  /// Show offline banner
  static Widget buildOfflineBanner({required Widget child}) {
    return Column(
      children: [
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: Colors.orange,
            child: Row(
              children: [
                const Icon(Icons.cloud_off, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'You are offline. Some features may not be available.',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final reconnected = await attemptReconnection();
                    if (reconnected) {
                      // Trigger a rebuild by calling this method again
                      buildOfflineBanner(child: child);
                    }
                  },
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }

  /// Reset offline state (call this when app starts)
  static void reset() {
    _isOffline = false;
    _lastConnectionAttempt = null;
  }
}