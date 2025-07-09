import 'dart:convert';
import 'package:http/http.dart' as http;
import '../security/security_config.dart';

/// Health check service to verify backend connectivity
class HealthService {
  static String get _baseUrl => SecurityConfig.apiUrl;

  /// Check if the backend server is reachable and healthy
  static Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile/'), // Use existing auth endpoint instead of non-existent /health/
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 401) {
        // 401 for auth endpoint means server is working but needs authentication
        return {
          'success': true,
          'healthy': true,
          'message': 'Server responding correctly',
        };
      } else if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': true,
            'healthy': true,
            'data': data,
          };
        } catch (e) {
          return {
            'success': true,
            'healthy': false,
            'error': 'Invalid response format',
          };
        }
      } else {
        return {
          'success': false,
          'healthy': false,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'healthy': false,
        'error': e.toString(),
      };
    }
  }

  /// Check authentication endpoints specifically
  static Future<Map<String, dynamic>> checkAuthEndpoints() async {
    try {
      
      // Test login endpoint with invalid credentials (should return 401)
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': 'healthcheck@test.com',
          'password': 'invalid_password',
        }),
      ).timeout(const Duration(seconds: 10));

      
      if (response.statusCode == 401) {
        // 401 is expected for invalid credentials - means endpoint is working
        return {
          'success': true,
          'auth_endpoints_working': true,
        };
      } else if (response.statusCode == 400) {
        // 400 is also acceptable - means endpoint is processing requests
        return {
          'success': true,
          'auth_endpoints_working': true,
        };
      } else {
        return {
          'success': false,
          'auth_endpoints_working': false,
          'error': 'Unexpected status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'auth_endpoints_working': false,
        'error': e.toString(),
      };
    }
  }

  /// Run comprehensive health check
  static Future<Map<String, dynamic>> runFullHealthCheck() async {
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'base_url': _baseUrl,
    };

    // Check backend health
    final healthCheck = await checkBackendHealth();
    results['backend_health'] = healthCheck;

    // Check auth endpoints
    final authCheck = await checkAuthEndpoints();
    results['auth_endpoints'] = authCheck;

    // Overall status
    final isHealthy = healthCheck['healthy'] == true && 
                     authCheck['auth_endpoints_working'] == true;
    
    results['overall_status'] = isHealthy ? 'healthy' : 'unhealthy';
    
    if (isHealthy) {
    } else {
    }

    return results;
  }
}