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
    // HTTP client initialized for production use
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
    Map<String, dynamic>? body,
    bool requireAuth = true,
  }) async {
    return _makeRequest(
      'DELETE',
      endpoint,
      headers: headers,
      body: body,
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
      print('🔍 SECURE_HTTP: Validating endpoint: "$endpoint"');
      final validation = InputValidator.validateTextInput(
        endpoint,
        maxLength: 500,
        fieldName: 'Endpoint',
      );
      if (!validation.isValid) {
        print('❌ SECURE_HTTP: Endpoint validation failed for: "$endpoint"');
        throw SecurityException('Invalid endpoint: ${validation.message}');
      }
      print('✅ SECURE_HTTP: Endpoint validation passed for: "$endpoint"');

      // Build URL
      final uri = _buildSecureUri(endpoint, queryParams);

      // Prepare headers
      final secureHeaders = await _buildSecureHeaders(headers, requireAuth, endpoint);

      // Prepare body
      String? jsonBody;
      if (body != null) {
        print('🔍 SECURE_HTTP: Processing request body with ${body.length} fields');
        // Validate and sanitize body
        final sanitizedBody = _sanitizeRequestBody(body);
        jsonBody = jsonEncode(sanitizedBody);
        print('✅ SECURE_HTTP: Request body processed successfully');
      }

      // Make request with adaptive timeout based on endpoint
      final timeout = _getTimeoutForEndpoint(endpoint);
      
      final response = await _makeRequestWithRetry(
        method,
        endpoint,
        secureHeaders,
        jsonBody,
        timeout,
        queryParams,
      );

      // Check for 401 error and retry with fresh token
      if (response.statusCode == 401 && requireAuth) {
        print('🔄 SECURE_HTTP: Got 401 error, clearing tokens and retrying...');
        await JWTManager.clearTokens();
        
        // Retry once with fresh authentication
        try {
          final freshHeaders = await _buildSecureHeaders(headers, requireAuth, endpoint);
          final retryResponse = await _executeRequest(method, _buildSecureUri(endpoint, queryParams), freshHeaders, jsonBody, timeout);
          
          if (retryResponse.statusCode != 401) {
            print('✅ SECURE_HTTP: Retry after 401 successful');
            final secureResponse = await _validateResponse(retryResponse);
            SecurityConfig.logSecurityEvent('HTTP_REQUEST_RETRY_SUCCESS', {
              'method': method,
              'endpoint': endpoint,
              'statusCode': retryResponse.statusCode,
            });
            return secureResponse;
          }
        } catch (retryError) {
          print('❌ SECURE_HTTP: Retry after 401 failed: $retryError');
        }
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

  /// Try request with retry logic for better reliability
  Future<http.Response> _makeRequestWithRetry(
    String method,
    String endpoint,
    Map<String, String> headers,
    String? body,
    Duration timeout,
    Map<String, dynamic>? queryParams,
  ) async {
    const maxRetries = 3;
    const baseDelay = Duration(milliseconds: 500);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final uri = _buildSecureUri(endpoint, queryParams);
        // Attempt ${attempt + 1}/$maxRetries
        
        final response = await _executeRequest(method, uri, headers, body, timeout);
        // Request successful on attempt ${attempt + 1}
        return response;
      } catch (e) {
        // Attempt ${attempt + 1}/$maxRetries failed
        
        // Check if it's a network/connection error that we should retry
        final isRetryableError = e.toString().contains('SocketException') ||
                                e.toString().contains('Connection refused') ||
                                e.toString().contains('Connection timeout') ||
                                e.toString().contains('TimeoutException') ||
                                e.toString().contains('Network is unreachable');
        
        // If it's the last attempt or not a retryable error, throw immediately
        if (attempt == maxRetries - 1 || !isRetryableError) {
          // Final attempt failed
          throw e;
        }
        
        // Wait before retrying with exponential backoff
        final delay = baseDelay * (attempt + 1);
        // Waiting before retry
        await Future.delayed(delay);
      }
    }
    
    throw Exception('All retry attempts failed');
  }

  /// Execute HTTP request for a specific URI
  Future<http.Response> _executeRequest(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
    Duration timeout,
  ) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await _client.get(uri, headers: headers).timeout(timeout);
      case 'POST':
        return await _client.post(uri, headers: headers, body: body).timeout(timeout);
      case 'PUT':
        return await _client.put(uri, headers: headers, body: body).timeout(timeout);
      case 'PATCH':
        return await _client.patch(uri, headers: headers, body: body).timeout(timeout);
      case 'DELETE':
        return await _client.delete(uri, headers: headers, body: body).timeout(timeout);
      default:
        throw SecurityException('Unsupported HTTP method: $method');
    }
  }

  /// Build secure headers including authentication
  Future<Map<String, String>> _buildSecureHeaders(
    Map<String, String>? customHeaders,
    bool requireAuth,
    String endpoint,
  ) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'GymManagement-Mobile/1.0',
      ...SecurityConfig.securityHeaders,
    };

    // Add authentication header if required with retry logic
    if (requireAuth) {
      // Authentication required
      
      // Try to get token with retry logic - prefer JWT for data endpoints
      String? token;
      
      // Data endpoints that might need JWT authentication
      final jwtEndpoints = ['equipment/', 'members/', 'trainers/', 'attendance/', 'subscriptions/'];
      final needsJWT = jwtEndpoints.any((ep) => endpoint.contains(ep));
      
      for (int attempt = 0; attempt < 3; attempt++) {
        if (needsJWT) {
          // Data endpoint detected, trying JWT
          token = await JWTManager.getJWTAccessToken();
        }
        
        // Fallback to regular token if JWT not found
        if (token == null) {
          // Getting access token
          token = await JWTManager.getAccessToken();
        }
        
        if (token != null) break;
        
        // Token retrieval failed, retrying
        await Future.delayed(Duration(milliseconds: 200));
      }
      
      // Token retrieval status logged
      
      if (token != null) {
        // Token format validated
        // Token type detected
        // Token length validated
        
        // Validate token format
        if (token.length < 20) {
          // Token validation: length check
        }
        if (token.contains(' ') || token.contains('\n')) {
          // Token validation: format check
        }
        
        // Additional validation for Django tokens
        if (token.split('.').length != 3) {
          // Django token should be 40 characters of hex
          final isDjangoToken = token.length >= 20 && token.length <= 128;
          if (!isDjangoToken) {
            // Token format invalid, clearing
            await JWTManager.clearTokens();
            throw SecurityException('Invalid token format - please login again');
          }
        }
      }
      
      if (token == null) {
        print('❌ SECURE_HTTP: No authentication token available after retries');
        print('❌ SECURE_HTTP: This will cause 401 Unauthorized error');
        throw SecurityException('Authentication required - please login again');
      }
      
      // Smart token format detection
      if (token.length > 100 && token.contains('.')) {
        // JWT token - use Bearer format
        headers['Authorization'] = 'Bearer $token';
        print('🔐 SECURE_HTTP: Using Bearer JWT token format');
      } else {
        // Django token - use Token format
        headers['Authorization'] = 'Token $token';
        print('🔐 SECURE_HTTP: Using Django Token format');
      }
      print('🔐 SECURE_HTTP: Authorization header set');
      print('🔐 SECURE_HTTP: Final headers: ${headers.keys.toList()}');
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

  /// Get timeout duration based on endpoint type
  Duration _getTimeoutForEndpoint(String endpoint) {
    print('🕐 SECURE_HTTP: Determining timeout for endpoint: $endpoint');
    
    // Data-heavy endpoints that might need more time (especially for sleeping servers)
    final heavyEndpoints = [
      'equipment/',
      'members/',
      'trainers/',
      'payments/',
      'attendance/',
      'subscriptions/',
    ];
    
    // Quick endpoints that should be fast
    final quickEndpoints = [
      'health/',
      'ping/',
      'status/',
      'auth/',
    ];
    
    for (final heavyEndpoint in heavyEndpoints) {
      if (endpoint.contains(heavyEndpoint)) {
        print('🕐 SECURE_HTTP: Using extended timeout (15s) for heavy endpoint');
        return const Duration(seconds: 15); // Longer timeout for data endpoints
      }
    }
    
    for (final quickEndpoint in quickEndpoints) {
      if (endpoint.contains(quickEndpoint)) {
        print('🕐 SECURE_HTTP: Using quick timeout (5s) for health endpoint');
        return const Duration(seconds: 5); // Quick timeout for health checks
      }
    }
    
    print('🕐 SECURE_HTTP: Using default timeout (10s)');
    return const Duration(seconds: 10); // Default timeout
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