import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Web-specific API service that handles CORS and browser-specific issues
class WebApiService {
  // Primary Railway URL - may need to be updated if Railway deployment URL changes
  static const String primaryUrl = 'https://gym-management-production-2168.up.railway.app/api';
  
  // Alternative Railway URLs to try (in case the primary URL changes)
  static const List<String> fallbackUrls = [
    'https://gym-management-production.up.railway.app/api',
    'https://gym-management-backend.up.railway.app/api',
    'https://gym-backend-production.up.railway.app/api',
  ];
  
  static String baseUrl = primaryUrl;
  
  /// Make a web-compatible HTTP request
  static Future<Map<String, dynamic>> makeRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      print('🌐 WEB API: Making $method request to: $endpoint');
      
      final url = '$baseUrl/$endpoint';
      final uri = Uri.parse(url);
      
      // Web-compatible headers
      final requestHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?headers,
      };
      
      // Only add mode headers if we're on web
      if (kIsWeb) {
        // These headers help with CORS on web
        requestHeaders['Access-Control-Allow-Origin'] = '*';
        requestHeaders['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS';
        requestHeaders['Access-Control-Allow-Headers'] = 'Content-Type, Authorization';
      }
      
      print('🌐 WEB API: Headers: $requestHeaders');
      if (body != null) {
        print('🌐 WEB API: Body keys: ${body.keys.toList()}');
      }
      
      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }
      
      print('🌐 WEB API: Response Status: ${response.statusCode}');
      print('🌐 WEB API: Response Headers: ${response.headers}');
      
      if (response.body.isNotEmpty) {
        print('🌐 WEB API: Response Body: ${response.body}');
      }
      
      final isSuccess = response.statusCode >= 200 && response.statusCode < 300;
      final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      
      if (kDebugMode && endpoint.contains('login') && isSuccess) {
        print('🔐 WEB API: LOGIN SUCCESS - Response data keys: ${data?.keys?.toList()}');
        print('🔐 WEB API: LOGIN SUCCESS - Contains token: ${data?.containsKey('token')}');
        print('🔐 WEB API: LOGIN SUCCESS - Token value type: ${data?['token']?.runtimeType}');
      }
      
      return {
        'success': isSuccess,
        'statusCode': response.statusCode,
        'headers': response.headers,
        'body': response.body,
        'data': data,
      };
      
    } catch (e) {
      print('❌ WEB API: Error: $e');
      print('❌ WEB API: Error Type: ${e.runtimeType}');
      
      String errorMessage = 'Request failed';
      
      if (e.toString().contains('XMLHttpRequest')) {
        errorMessage = 'CORS Error: Browser security blocked the request';
      } else if (e.toString().contains('Load failed')) {
        errorMessage = 'Network Error: Cannot reach server (possible CORS issue)';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Timeout: Server took too long to respond';
      }
      
      return {
        'success': false,
        'error': e.toString(),
        'message': errorMessage,
        'errorType': e.runtimeType.toString(),
      };
    }
  }
  
  /// Register a new user with web-compatible request
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
        'gym_address': gymAddress ?? 'Default Address',
        'gym_description': gymDescription ?? 'Default Description',
        'phone_number': phoneNumber ?? '',
      },
    );
  }
  
  /// Login with web-compatible request
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
    );
  }
  
  /// Test connectivity
  static Future<Map<String, dynamic>> testConnectivity() async {
    return await makeRequest(
      method: 'GET',
      endpoint: 'auth/register/', // This should return 405 but proves connectivity
    );
  }
}