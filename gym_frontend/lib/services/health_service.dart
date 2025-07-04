import 'dart:convert';
import 'package:http/http.dart' as http;
import '../security/security_config.dart';

/// Health check service to verify backend connectivity
class HealthService {
  static String get _baseUrl => SecurityConfig.apiUrl;

  /// Check if the backend server is reachable and healthy
  static Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      print('🏥 HEALTH: Checking backend connectivity...');
      
      final response = await http.get(
        Uri.parse('${_baseUrl.replaceAll('/api', '')}/health/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('🏥 HEALTH: Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ HEALTH: Backend is healthy');
          print('🏥 HEALTH: Database: ${data['services']?['database']?['healthy'] ? '✅' : '❌'}');
          print('🏥 HEALTH: Cache: ${data['services']?['cache']?['healthy'] ? '✅' : '❌'}');
          
          return {
            'success': true,
            'healthy': true,
            'data': data,
          };
        } catch (e) {
          print('⚠️ HEALTH: Backend responded but JSON parsing failed: $e');
          return {
            'success': true,
            'healthy': false,
            'error': 'Invalid response format',
          };
        }
      } else {
        print('❌ HEALTH: Backend returned HTTP ${response.statusCode}');
        return {
          'success': false,
          'healthy': false,
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 HEALTH: Backend health check failed: $e');
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
      print('🔐 HEALTH: Checking authentication endpoints...');
      
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

      print('🔐 HEALTH: Auth endpoint status: ${response.statusCode}');
      
      if (response.statusCode == 401) {
        // 401 is expected for invalid credentials - means endpoint is working
        print('✅ HEALTH: Auth endpoints are working (401 for invalid creds)');
        return {
          'success': true,
          'auth_endpoints_working': true,
        };
      } else if (response.statusCode == 400) {
        // 400 is also acceptable - means endpoint is processing requests
        print('✅ HEALTH: Auth endpoints are working (400 for bad request)');
        return {
          'success': true,
          'auth_endpoints_working': true,
        };
      } else {
        print('⚠️ HEALTH: Auth endpoint returned unexpected status: ${response.statusCode}');
        print('Response body: ${response.body}');
        return {
          'success': false,
          'auth_endpoints_working': false,
          'error': 'Unexpected status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('💥 HEALTH: Auth endpoint check failed: $e');
      return {
        'success': false,
        'auth_endpoints_working': false,
        'error': e.toString(),
      };
    }
  }

  /// Run comprehensive health check
  static Future<Map<String, dynamic>> runFullHealthCheck() async {
    print('\n🚀 HEALTH: Running comprehensive health check...');
    print('=' * 50);
    
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
    
    print('=' * 50);
    if (isHealthy) {
      print('✅ HEALTH: All systems are working correctly!');
      print('🎉 HEALTH: Your Flutter app should be able to authenticate.');
    } else {
      print('❌ HEALTH: Issues detected with backend connectivity.');
      print('🔧 HEALTH: Please check network configuration and Django server.');
    }
    print('');

    return results;
  }
}