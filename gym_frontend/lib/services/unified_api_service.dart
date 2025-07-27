import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../security/secure_http_client.dart';
import '../security/security_config.dart';
import '../utils/network_test.dart';

/// Unified API service that handles all backend communication
/// Works consistently across web and mobile platforms
class UnifiedApiService {
  static const String _version = 'v1';
  static const Duration _defaultTimeout = Duration(seconds: 30);
  
  // Configuration based on environment
  static const Map<String, String> _baseUrls = {
    'production': 'https://gym-management-production-2168.up.railway.app/api',
    'staging': 'https://gym-management-staging.up.railway.app/api',
    'development': 'http://localhost:8000/api',
  };
  
  // Fallback URLs for production
  static const List<String> _fallbackUrls = [
    'https://gym-management-production.up.railway.app/api',
    'https://gym-backend-production.up.railway.app/api',
  ];
  
  // Current environment (can be overridden)
  static String _environment = kDebugMode ? 'development' : 'production';
  static String get environment => _environment;
  
  // Get base URL for current environment
  static String get baseUrl => _baseUrls[_environment] ?? _baseUrls['production']!;
  
  // HTTP client (secure for mobile, regular for web)
  static http.Client get _httpClient {
    if (kIsWeb) {
      return http.Client();
    } else {
      return SecureHttpClient.instance;
    }
  }
  
  /// Set environment (for testing or different deployments)
  static void setEnvironment(String env) {
    if (_baseUrls.containsKey(env)) {
      _environment = env;
    }
  }
  
  /// Make authenticated API request
  static Future<Map<String, dynamic>> makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      // Network connectivity check (non-blocking)
      if (!kIsWeb) {
        await NetworkTest.testNetworkConnection();
      }
      
      // Prepare headers
      final requestHeaders = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'GymManagement/${_version} (${Platform.operatingSystem})',
        ...?headers,
      };
      
      // Add authentication if required
      if (requiresAuth) {
        // TODO: Add token from secure storage
        // final token = await SecureTokenStorage.getToken();
        // if (token != null) {
        //   requestHeaders['Authorization'] = 'Bearer $token';
        // }
      }
      
      // Try primary URL first
      final response = await _makeHttpRequest(
        method: method,
        url: '$baseUrl/$endpoint',
        headers: requestHeaders,
        body: body,
        timeout: timeout ?? _defaultTimeout,
      );
      
      if (response.success) {
        _logRequest(method, endpoint, response.statusCode, stopwatch.elapsed);
        return response.toMap();
      }
      
      // If primary fails, try fallback URLs (production only)
      if (_environment == 'production') {
        for (final fallbackUrl in _fallbackUrls) {
          try {
            final fallbackResponse = await _makeHttpRequest(
              method: method,
              url: '$fallbackUrl/$endpoint',
              headers: requestHeaders,
              body: body,
              timeout: timeout ?? _defaultTimeout,
            );
            
            if (fallbackResponse.success) {
              _logRequest(method, endpoint, fallbackResponse.statusCode, stopwatch.elapsed, fallback: true);
              return fallbackResponse.toMap();
            }
          } catch (e) {
            // Continue to next fallback
            continue;
          }
        }
      }
      
      // All attempts failed
      throw ApiException(
        'All API endpoints failed',
        statusCode: response.statusCode,
        endpoint: endpoint,
      );
      
    } catch (e) {
      _logError(method, endpoint, e, stopwatch.elapsed);
      rethrow;
    }
  }
  
  /// Make HTTP request with proper error handling
  static Future<_ApiResponse> _makeHttpRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    Map<String, dynamic>? body,
    required Duration timeout,
  }) async {
    final uri = Uri.parse(url);
    http.Response response;
    
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _httpClient.get(uri, headers: headers).timeout(timeout);
          break;
        case 'POST':
          response = await _httpClient.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await _httpClient.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await _httpClient.delete(uri, headers: headers).timeout(timeout);
          break;
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
      
      return _ApiResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
        success: response.statusCode >= 200 && response.statusCode < 300,
      );
      
    } catch (e) {
      return _ApiResponse(
        statusCode: 0,
        body: '',
        headers: {},
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Authentication endpoints
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await makeRequest(
      method: 'POST',
      endpoint: 'auth/login/',
      body: {
        'email': email,
        'password': password,
      },
      requiresAuth: false,
    );
  }
  
  static Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String gymName,
    String? gymAddress,
    String? gymDescription,
    String? phoneNumber,
  }) async {
    return await makeRequest(
      method: 'POST',
      endpoint: 'auth/register/',
      body: {
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
        'gym_name': gymName,
        'gym_address': gymAddress ?? '',
        'gym_description': gymDescription ?? '',
        'phone_number': phoneNumber ?? '',
      },
      requiresAuth: false,
    );
  }
  
  static Future<Map<String, dynamic>> googleAuth({
    required String googleToken,
  }) async {
    return await makeRequest(
      method: 'POST',
      endpoint: 'auth/google/',
      body: {
        'google_token': googleToken,
      },
      requiresAuth: false,
    );
  }
  
  static Future<Map<String, dynamic>> logout() async {
    return await makeRequest(
      method: 'POST',
      endpoint: 'auth/logout/',
    );
  }
  
  static Future<Map<String, dynamic>> getProfile() async {
    return await makeRequest(
      method: 'GET',
      endpoint: 'auth/profile/',
    );
  }
  
  /// Configuration check endpoint
  static Future<Map<String, dynamic>> checkGoogleConfig() async {
    return await makeRequest(
      method: 'GET',
      endpoint: 'auth/google/config/',
      requiresAuth: false,
    );
  }
  
  /// Test connectivity
  static Future<bool> testConnectivity() async {
    try {
      await makeRequest(
        method: 'GET',
        endpoint: 'auth/register/',
        requiresAuth: false,
        timeout: Duration(seconds: 10),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Logging methods
  static void _logRequest(String method, String endpoint, int statusCode, Duration duration, {bool fallback = false}) {
    final fallbackText = fallback ? ' (fallback)' : '';
    print('🌐 API: $method $endpoint -> $statusCode (${duration.inMilliseconds}ms)$fallbackText');
  }
  
  static void _logError(String method, String endpoint, dynamic error, Duration duration) {
    print('❌ API: $method $endpoint -> ERROR: $error (${duration.inMilliseconds}ms)');
  }
}

/// API response wrapper
class _ApiResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;
  final bool success;
  final String? error;
  
  _ApiResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.success,
    this.error,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'statusCode': statusCode,
      'headers': headers,
      'body': body,
      'data': body.isNotEmpty ? jsonDecode(body) : null,
      'error': error,
    };
  }
}

/// Custom API exception
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? endpoint;
  
  ApiException(this.message, {this.statusCode, this.endpoint});
  
  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${endpoint != null ? ' (Endpoint: $endpoint)' : ''}';
  }
}