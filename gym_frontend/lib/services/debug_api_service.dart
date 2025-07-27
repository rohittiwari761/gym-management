import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../security/jwt_manager.dart';
import '../security/secure_http_client.dart';

class DebugApiService {
  static final SecureHttpClient _httpClient = SecureHttpClient();
  
  /// Test if authentication token is available and working
  static Future<Map<String, dynamic>> testAuthentication() async {
    try {
      print('🔍 DEBUG_API: Testing authentication...');
      
      // Test 1: Check token availability
      final token = await JWTManager.getAccessToken();
      print('🔍 DEBUG_API: Token available: ${token != null}');
      
      if (token == null) {
        return {
          'success': false,
          'error': 'No authentication token available',
          'step': 'token_retrieval'
        };
      }
      
      print('🔍 DEBUG_API: Token length: ${token.length}');
      print('🔍 DEBUG_API: Token starts with: ${token.substring(0, 20)}...');
      
      // Test 2: Test auth profile endpoint (should work)
      try {
        final response = await _httpClient.get('auth/profile/');
        print('🔍 DEBUG_API: Auth profile test - Status: ${response.statusCode}');
        
        if (response.isSuccess) {
          print('✅ DEBUG_API: Authentication is working properly');
          return {
            'success': true,
            'token_available': true,
            'auth_profile_working': true,
            'user_data': response.data
          };
        } else {
          print('❌ DEBUG_API: Auth profile failed - ${response.errorMessage}');
          return {
            'success': false,
            'error': response.errorMessage,
            'step': 'auth_profile_test',
            'status_code': response.statusCode
          };
        }
      } catch (e) {
        print('❌ DEBUG_API: Auth profile exception - $e');
        return {
          'success': false,
          'error': e.toString(),
          'step': 'auth_profile_test'
        };
      }
    } catch (e) {
      print('❌ DEBUG_API: Authentication test failed - $e');
      return {
        'success': false,
        'error': e.toString(),
        'step': 'initial_setup'
      };
    }
  }
  
  /// Test payments endpoint specifically
  static Future<Map<String, dynamic>> testPaymentsEndpoint() async {
    try {
      print('🔍 DEBUG_API: Testing payments endpoint...');
      
      // First ensure authentication is working
      final authTest = await testAuthentication();
      if (!authTest['success']) {
        return {
          'success': false,
          'error': 'Authentication failed: ${authTest['error']}',
          'auth_test': authTest
        };
      }
      
      // Test payments endpoint
      try {
        final response = await _httpClient.get('payments/');
        print('🔍 DEBUG_API: Payments endpoint test - Status: ${response.statusCode}');
        
        if (response.isSuccess) {
          print('✅ DEBUG_API: Payments endpoint is working properly');
          final data = response.data;
          int paymentCount = 0;
          
          if (data is Map<String, dynamic> && data.containsKey('results')) {
            paymentCount = (data['results'] as List).length;
          } else if (data is List) {
            paymentCount = data.length;
          }
          
          return {
            'success': true,
            'payments_count': paymentCount,
            'response_type': data?.runtimeType.toString(),
            'auth_test': authTest
          };
        } else {
          print('❌ DEBUG_API: Payments endpoint failed - ${response.errorMessage}');
          return {
            'success': false,
            'error': response.errorMessage,
            'status_code': response.statusCode,
            'auth_test': authTest
          };
        }
      } catch (e) {
        print('❌ DEBUG_API: Payments endpoint exception - $e');
        return {
          'success': false,
          'error': e.toString(),
          'auth_test': authTest
        };
      }
    } catch (e) {
      print('❌ DEBUG_API: Payments test failed - $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
  
  /// Test revenue analytics endpoint for comparison
  static Future<Map<String, dynamic>> testRevenueEndpoint() async {
    try {
      print('🔍 DEBUG_API: Testing revenue analytics endpoint...');
      
      final response = await _httpClient.get('payments/revenue_analytics/');
      print('🔍 DEBUG_API: Revenue endpoint test - Status: ${response.statusCode}');
      
      if (response.isSuccess) {
        print('✅ DEBUG_API: Revenue endpoint is working properly');
        return {
          'success': true,
          'data': response.data
        };
      } else {
        print('❌ DEBUG_API: Revenue endpoint failed - ${response.errorMessage}');
        return {
          'success': false,
          'error': response.errorMessage,
          'status_code': response.statusCode
        };
      }
    } catch (e) {
      print('❌ DEBUG_API: Revenue test failed - $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}