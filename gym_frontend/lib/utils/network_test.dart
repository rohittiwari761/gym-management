import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../security/security_config.dart';

class NetworkTest {
  static Future<void> testNetworkConnection() async {
    print('🌐 NETWORK_TEST: Starting network connectivity test...');
    print('🌐 NETWORK_TEST: Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
    print('🌐 NETWORK_TEST: API URL: ${SecurityConfig.apiUrl}');
    
    try {
      // Test 1: Basic connectivity
      print('🔍 NETWORK_TEST: Testing basic connectivity...');
      final response = await http.get(
        Uri.parse('${SecurityConfig.apiUrl}/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('✅ NETWORK_TEST: Basic connectivity successful');
      print('📡 NETWORK_TEST: Status Code: ${response.statusCode}');
      print('📡 NETWORK_TEST: Response Headers: ${response.headers}');
      print('📡 NETWORK_TEST: Response Body: ${response.body}');
      
      // Test 2: Login endpoint specifically
      print('🔍 NETWORK_TEST: Testing login endpoint...');
      final loginResponse = await http.post(
        Uri.parse('${SecurityConfig.apiUrl}/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'test@example.com',
          'password': 'testpassword',
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('✅ NETWORK_TEST: Login endpoint reachable');
      print('📡 NETWORK_TEST: Login Status Code: ${loginResponse.statusCode}');
      
    } catch (e) {
      print('❌ NETWORK_TEST: Network test failed: $e');
      print('🔍 NETWORK_TEST: Error type: ${e.runtimeType}');
      
      if (kIsWeb) {
        print('🌐 NETWORK_TEST: Web platform - skipping localhost fallbacks (mixed content blocked)');
        print('💡 NETWORK_TEST: Railway backend may be down or URL changed');
        print('🔧 NETWORK_TEST: Possible solutions:');
        print('   - Check Railway deployment status');
        print('   - Verify Railway URL is correct');
        print('   - Use email login (may work if backend is accessible)');
      } else {
        // Test fallback URLs only on mobile platforms
        print('🔄 NETWORK_TEST: Testing fallback URLs...');
        for (final url in SecurityConfig.localFallbackUrls) {
          try {
            print('🔍 NETWORK_TEST: Testing fallback URL: $url');
            final fallbackResponse = await http.get(
              Uri.parse('$url/'),
              headers: {'Content-Type': 'application/json'},
            ).timeout(const Duration(seconds: 5));
            
            print('✅ NETWORK_TEST: Fallback URL working: $url');
            print('📡 NETWORK_TEST: Status: ${fallbackResponse.statusCode}');
            break;
          } catch (fallbackError) {
            print('❌ NETWORK_TEST: Fallback URL failed: $url - $fallbackError');
          }
        }
      }
    }
  }
}