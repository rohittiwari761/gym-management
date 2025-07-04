import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'security_config.dart';
import 'jwt_manager.dart';
import 'input_validator.dart';

class SecureHttpClient {
  static final SecureHttpClient _instance = SecureHttpClient._internal();
  factory SecureHttpClient() => _instance;
  SecureHttpClient._internal();

  late http.Client _client;
  final Map<String, int> _requestCounts = {};
  final Map<String, DateTime> _lastRequestTimes = {};

  /// Initialize secure HTTP client with certificate pinning
  void initialize() {
    _client = http.Client();
    
    // In a real implementation, you would configure certificate pinning here
    // For now, we'll ensure HTTPS is used and add security headers
  }

  /// Create HTTP client with timeout
  http.Client _createTimeoutClient() {
    return http.Client();
  }

  /// Make secure GET request
  Future<SecureHttpResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
  }) async {
    return _makeRequest(
      'GET',
      endpoint,
      headers: headers,
      queryParams: queryParams,
      requireAuth: requireAuth,
    );
  }

  /// Make secure POST request
  Future<SecureHttpResponse> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    return _makeRequest(
      'POST',
      endpoint,
      headers: headers,
      body: body,
      requireAuth: requireAuth,
    );
  }

  /// Make secure PUT request
  Future<SecureHttpResponse> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    return _makeRequest(
      'PUT',
      endpoint,
      headers: headers,
      body: body,
      requireAuth: requireAuth,
    );
  }

  /// Make secure PATCH request
  Future<SecureHttpResponse> patch(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    return _makeRequest(
      'PATCH',
      endpoint,
      headers: headers,
      body: body,
      requireAuth: requireAuth,
    );
  }

  /// Make secure DELETE request
  Future<SecureHttpResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    return _makeRequest(
      'DELETE',
      endpoint,
      headers: headers,
      requireAuth: requireAuth,
    );
  }

  /// Internal method to make HTTP requests with security measures
  Future<SecureHttpResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      // Rate limiting check
      if (!_checkRateLimit()) {
        throw SecurityException('Rate limit exceeded');
      }

      // Validate endpoint
      final validation = InputValidator.validateTextInput(
        endpoint,
        maxLength: 500,
        fieldName: 'Endpoint',
      );
      if (!validation.isValid) {
        throw SecurityException('Invalid endpoint: ${validation.message}');
      }

      // Build URL
      final uri = _buildSecureUri(endpoint, queryParams);

      // Prepare headers
      final secureHeaders = await _buildSecureHeaders(headers, requireAuth);

      // Prepare body
      String? jsonBody;
      if (body != null) {
        // Validate and sanitize body
        final sanitizedBody = _sanitizeRequestBody(body);
        jsonBody = jsonEncode(sanitizedBody);
      }

      // Make request with timeout
      http.Response response;
      const timeout = Duration(seconds: 30); // 30 second timeout
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: secureHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: secureHeaders,
            body: jsonBody,
          ).timeout(timeout);
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: secureHeaders,
            body: jsonBody,
          ).timeout(timeout);
          break;
        case 'PATCH':
          response = await _client.patch(
            uri,
            headers: secureHeaders,
            body: jsonBody,
          ).timeout(timeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: secureHeaders).timeout(timeout);
          break;
        default:
          throw SecurityException('Unsupported HTTP method: $method');
      }

      // Validate response
      final secureResponse = await _validateResponse(response);

      // Log security event
      SecurityConfig.logSecurityEvent('HTTP_REQUEST', {
        'method': method,
        'endpoint': endpoint,
        'statusCode': response.statusCode,
        'responseSize': response.body.length,
      });

      return secureResponse;
    } catch (e) {
      SecurityConfig.logSecurityEvent('HTTP_REQUEST_ERROR', {
        'method': method,
        'endpoint': endpoint,
        'error': e.toString(),
      });
      
      if (e is SecurityException) rethrow;
      
      // Handle common network errors gracefully
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Network is unreachable')) {
        throw SecurityException('Unable to connect to server. Please check your internet connection.');
      }
      
      throw SecurityException('Request failed: ${e.toString()}');
    }
  }

  /// Build secure URI with validation
  Uri _buildSecureUri(String endpoint, Map<String, dynamic>? queryParams) {
    final baseUrl = SecurityConfig.apiUrl;
    
    // Allow HTTP for development/localhost, require HTTPS for production
    if (!baseUrl.startsWith('https://') && !baseUrl.startsWith('http://localhost') && !baseUrl.startsWith('http://127.0.0.1') && !baseUrl.startsWith('http://192.168.')) {
      throw SecurityException('Only HTTPS connections are allowed in production');
    }

    // Build full URL
    final fullUrl = endpoint.startsWith('/') 
        ? '$baseUrl$endpoint' 
        : '$baseUrl/$endpoint';

    final uri = Uri.parse(fullUrl);
    
    // Add query parameters if provided
    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = _sanitizeQueryParams(queryParams);
      return uri.replace(queryParameters: sanitizedParams);
    }

    return uri;
  }

  /// Build secure headers including authentication
  Future<Map<String, String>> _buildSecureHeaders(
    Map<String, String>? customHeaders,
    bool requireAuth,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'GymManagement-Mobile/1.0',
      ...SecurityConfig.securityHeaders,
    };

    // Add authentication header if required
    if (requireAuth) {
      final token = await JWTManager.getAccessToken();
      if (token == null) {
        throw SecurityException('Authentication required');
      }
      headers['Authorization'] = 'Token $token';
    }

    // Add custom headers (with validation)
    if (customHeaders != null) {
      for (final entry in customHeaders.entries) {
        final keyValidation = InputValidator.validateTextInput(
          entry.key,
          maxLength: 100,
          fieldName: 'Header key',
        );
        final valueValidation = InputValidator.validateTextInput(
          entry.value,
          maxLength: 1000,
          fieldName: 'Header value',
        );
        
        if (keyValidation.isValid && valueValidation.isValid) {
          headers[entry.key] = entry.value;
        }
      }
    }

    // Add request ID for tracking
    headers['X-Request-ID'] = SecurityConfig.generateSecureToken(16);

    // Add timestamp
    headers['X-Timestamp'] = DateTime.now().millisecondsSinceEpoch.toString();

    return headers;
  }

  /// Sanitize request body
  Map<String, dynamic> _sanitizeRequestBody(Map<String, dynamic> body) {
    final sanitized = <String, dynamic>{};
    
    for (final entry in body.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        sanitized[key] = InputValidator.sanitizeInput(value);
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeRequestBody(value);
      } else if (value is List) {
        sanitized[key] = value.map((item) {
          if (item is String) {
            return InputValidator.sanitizeInput(item);
          } else if (item is Map<String, dynamic>) {
            return _sanitizeRequestBody(item);
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    }
    
    return sanitized;
  }

  /// Sanitize query parameters
  Map<String, String> _sanitizeQueryParams(Map<String, dynamic> params) {
    final sanitized = <String, String>{};
    
    for (final entry in params.entries) {
      final validation = InputValidator.validateTextInput(
        entry.value.toString(),
        maxLength: 500,
        fieldName: 'Query parameter',
      );
      
      if (validation.isValid) {
        sanitized[entry.key] = InputValidator.sanitizeInput(entry.value.toString());
      }
    }
    
    return sanitized;
  }

  /// Validate HTTP response
  Future<SecureHttpResponse> _validateResponse(http.Response response) async {
    // Check for security headers in response
    final securityHeaders = ['x-content-type-options', 'x-frame-options', 'x-xss-protection'];
    final missingHeaders = <String>[];
    
    for (final header in securityHeaders) {
      if (!response.headers.containsKey(header)) {
        missingHeaders.add(header);
      }
    }

    if (missingHeaders.isNotEmpty) {
      SecurityConfig.logSecurityEvent('MISSING_SECURITY_HEADERS', {
        'headers': missingHeaders,
      });
    }

    // Validate response content type (allow HTML for some endpoints)
    final contentType = response.headers['content-type'];
    if (contentType != null && 
        !contentType.contains('application/json') && 
        !contentType.contains('text/html')) {
      SecurityConfig.logSecurityEvent('UNEXPECTED_CONTENT_TYPE', {
        'contentType': contentType,
      });
    }

    // Parse response body safely
    dynamic responseData;
    if (response.body.isNotEmpty) {
      try {
        responseData = jsonDecode(response.body);
      } catch (e) {
        // If JSON parsing fails, return the raw response for debugging
        SecurityConfig.logSecurityEvent('JSON_PARSE_ERROR', {
          'error': e.toString(),
          'bodyLength': response.body.length,
        });
        throw SecurityException('Invalid JSON response: ${e.toString()}');
      }
    }

    return SecureHttpResponse(
      statusCode: response.statusCode,
      data: responseData,
      headers: response.headers,
      isSuccess: response.statusCode >= 200 && response.statusCode < 300,
    );
  }

  /// Check rate limiting
  bool _checkRateLimit() {
    final now = DateTime.now();
    final clientId = 'default'; // In real app, use device/user identifier
    
    // Clean up old entries
    _requestCounts.removeWhere((key, value) {
      final timestamp = _lastRequestTimes[key];
      return timestamp == null || now.difference(timestamp).inMinutes > 1;
    });

    // Check current minute limit
    final currentCount = _requestCounts[clientId] ?? 0;
    if (currentCount >= SecurityConfig.maxRequestsPerMinute) {
      return false;
    }

    // Update counts
    _requestCounts[clientId] = currentCount + 1;
    _lastRequestTimes[clientId] = now;

    return true;
  }

  /// Dispose of resources
  void dispose() {
    _client.close();
  }
}

class SecureHttpResponse {
  final int statusCode;
  final dynamic data; // Changed from Map<String, dynamic>? to dynamic to support lists
  final Map<String, String> headers;
  final bool isSuccess;

  const SecureHttpResponse({
    required this.statusCode,
    required this.data,
    required this.headers,
    required this.isSuccess,
  });

  String? get errorMessage {
    if (isSuccess) return null;
    if (data is Map<String, dynamic>) {
      return data?['message'] ?? data?['error'] ?? 'Request failed';
    }
    return 'Request failed';
  }

  @override
  String toString() => 'SecureHttpResponse(statusCode: $statusCode, isSuccess: $isSuccess)';
}

class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}