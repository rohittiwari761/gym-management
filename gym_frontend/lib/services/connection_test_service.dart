import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../security/security_config.dart';
import '../security/secure_http_client.dart';

class ConnectionTestService {
  static final ConnectionTestService _instance = ConnectionTestService._internal();
  factory ConnectionTestService() => _instance;
  ConnectionTestService._internal();

  final SecureHttpClient _httpClient = SecureHttpClient();
  
  /// Test connection to the backend with detailed diagnostics
  Future<Map<String, dynamic>> testConnection() async {
    print('🔍 CONNECTION_TEST: Starting comprehensive connection test...');
    
    final results = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': kIsWeb ? 'web' : 'mobile',
      'tests': <String, dynamic>{},
      'overall_status': 'testing',
      'recommendations': <String>[],
    };
    
    try {
      // Test 1: Basic internet connectivity
      print('🌐 CONNECTION_TEST: Testing basic internet connectivity...');
      final internetTest = await _testInternetConnectivity();
      results['tests']['internet'] = internetTest;
      
      // Test 2: Backend server reachability
      print('🏥 CONNECTION_TEST: Testing backend server reachability...');
      final backendTest = await _testBackendConnection();
      results['tests']['backend'] = backendTest;
      
      // Test 3: Authentication endpoint
      print('🔐 CONNECTION_TEST: Testing authentication endpoint...');
      final authTest = await _testAuthEndpoint();
      results['tests']['auth'] = authTest;
      
      // Test 4: Payment endpoint specifically
      print('💰 CONNECTION_TEST: Testing payment endpoint...');
      final paymentTest = await _testPaymentEndpoint();
      results['tests']['payment'] = paymentTest;
      
      // Analyze results and provide recommendations
      _analyzeResults(results);
      
      print('✅ CONNECTION_TEST: All tests completed');
      return results;
      
    } catch (e) {
      print('❌ CONNECTION_TEST: Test suite failed: $e');
      results['overall_status'] = 'failed';
      results['error'] = e.toString();
      return results;
    }
  }
  
  /// Test basic internet connectivity
  Future<Map<String, dynamic>> _testInternetConnectivity() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      if (kIsWeb) {
        // For web, we can't directly test DNS, so we'll test a simple HTTP request
        final response = await _httpClient.get('https://httpbin.org/get').timeout(
          Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Internet test timed out'),
        );
        
        stopwatch.stop();
        return {
          'status': 'success',
          'latency_ms': stopwatch.elapsedMilliseconds,
          'method': 'http_test',
        };
      } else {
        // For mobile, test DNS lookup
        final result = await InternetAddress.lookup('google.com').timeout(
          Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('DNS lookup timed out'),
        );
        
        stopwatch.stop();
        return {
          'status': 'success',
          'latency_ms': stopwatch.elapsedMilliseconds,
          'method': 'dns_lookup',
          'resolved_ips': result.map((addr) => addr.address).toList(),
        };
      }
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
        'method': kIsWeb ? 'http_test' : 'dns_lookup',
      };
    }
  }
  
  /// Test backend server connection
  Future<Map<String, dynamic>> _testBackendConnection() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Test a simple GET request to the backend root
      final response = await _httpClient.get('', requireAuth: false).timeout(
        Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Backend test timed out'),
      );
      
      stopwatch.stop();
      return {
        'status': 'success',
        'status_code': response.statusCode,
        'latency_ms': stopwatch.elapsedMilliseconds,
        'backend_url': SecurityConfig.apiUrl,
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
        'backend_url': SecurityConfig.apiUrl,
      };
    }
  }
  
  /// Test authentication endpoint
  Future<Map<String, dynamic>> _testAuthEndpoint() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Test auth endpoint with a simple request (expect 401/403)
      final response = await _httpClient.get('auth/profile/', requireAuth: false).timeout(
        Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Auth test timed out'),
      );
      
      stopwatch.stop();
      return {
        'status': 'success',
        'status_code': response.statusCode,
        'latency_ms': stopwatch.elapsedMilliseconds,
        'note': 'Expected 401/403 for unauthenticated request',
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }
  
  /// Test payment endpoint specifically
  Future<Map<String, dynamic>> _testPaymentEndpoint() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // Test payment endpoint (expect 401 for unauthenticated)
      final response = await _httpClient.get('payments/', requireAuth: false).timeout(
        Duration(seconds: 8),
        onTimeout: () => throw TimeoutException('Payment test timed out'),
      );
      
      stopwatch.stop();
      return {
        'status': 'success',
        'status_code': response.statusCode,
        'latency_ms': stopwatch.elapsedMilliseconds,
        'note': 'Expected 401 for unauthenticated request',
      };
    } catch (e) {
      return {
        'status': 'failed',
        'error': e.toString(),
      };
    }
  }
  
  /// Analyze test results and provide recommendations
  void _analyzeResults(Map<String, dynamic> results) {
    final tests = results['tests'] as Map<String, dynamic>;
    final recommendations = results['recommendations'] as List<String>;
    
    bool allTestsPassed = true;
    
    // Check internet connectivity
    if (tests['internet']['status'] != 'success') {
      allTestsPassed = false;
      recommendations.add('Check your internet connection');
    }
    
    // Check backend connectivity
    if (tests['backend']['status'] != 'success') {
      allTestsPassed = false;
      recommendations.add('Backend server is unreachable - check server status');
    }
    
    // Check authentication endpoint
    if (tests['auth']['status'] != 'success') {
      allTestsPassed = false;
      recommendations.add('Authentication service is having issues');
    }
    
    // Check payment endpoint
    if (tests['payment']['status'] != 'success') {
      allTestsPassed = false;
      recommendations.add('Payment service is having issues - this explains the payment tab problems');
    }
    
    // Check latency
    for (final test in tests.values) {
      if (test is Map<String, dynamic> && test.containsKey('latency_ms')) {
        final latency = test['latency_ms'] as int;
        if (latency > 3000) {
          recommendations.add('High latency detected (${latency}ms) - connection is slow');
        }
      }
    }
    
    results['overall_status'] = allTestsPassed ? 'healthy' : 'issues_detected';
    
    if (allTestsPassed) {
      recommendations.add('All connectivity tests passed - network should be working');
    }
  }
  
  /// Quick connectivity check
  Future<bool> isConnected() async {
    try {
      final result = await testConnection();
      return result['overall_status'] == 'healthy';
    } catch (e) {
      return false;
    }
  }
}