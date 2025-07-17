import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:html' as html;
import 'security_config.dart';

class JWTManager {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(
      dbName: 'gym_management_secure_storage',
      publicKey: 'gym_management_public_key',
    ),
  );
  
  // Fallback storage for web when IndexedDB fails
  static final Map<String, String> _webFallbackStorage = {};

  static const String _accessTokenKey = 'secure_access_token';
  static const String _refreshTokenKey = 'secure_refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  static const String _userRoleKey = 'user_role';
  static const String _sessionIdKey = 'session_id';
  static const String _sessionPersistentKey = 'session_persistent';

  /// Check if a token is a JWT token (has 3 parts separated by dots)
  static bool _isJWTToken(String token) {
    return token.split('.').length == 3;
  }
  
  /// Safe storage write with fallback for web platform
  static Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      print('✅ JWT_MANAGER: Secure storage write successful for key: $key');
    } catch (e) {
      print('⚠️ JWT_MANAGER: Secure storage failed, using fallback: $e');
      if (kIsWeb) {
        _webFallbackStorage[key] = value;
        // Also try localStorage as backup (with prefix for consistency)
        try {
          final prefixedKey = 'gym_management_public_key.$key';
          html.window.localStorage[prefixedKey] = value;
          print('✅ JWT_MANAGER: Fallback localStorage write successful with prefix');
        } catch (storageError) {
          print('❌ JWT_MANAGER: localStorage also failed: $storageError');
        }
      }
    }
  }
  
  /// Safe storage read with fallback for web platform
  static Future<String?> _safeRead(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        print('✅ JWT_MANAGER: Secure storage read successful for key: $key');
        return value;
      }
    } catch (e) {
      print('⚠️ JWT_MANAGER: Secure storage read failed, trying fallback: $e');
    }
    
    // Try fallback storage on web
    if (kIsWeb) {
      // Try in-memory fallback first
      if (_webFallbackStorage.containsKey(key)) {
        print('✅ JWT_MANAGER: Retrieved from fallback memory storage');
        return _webFallbackStorage[key];
      }
      
      // Try localStorage as backup (with prefix)
      try {
        final prefixedKey = 'gym_management_public_key.$key';
        final value = html.window.localStorage[prefixedKey];
        if (value != null) {
          print('✅ JWT_MANAGER: Retrieved from localStorage fallback with prefix');
          return value;
        }
        
        // Also try without prefix for compatibility
        final directValue = html.window.localStorage[key];
        if (directValue != null) {
          print('✅ JWT_MANAGER: Retrieved from localStorage fallback direct');
          return directValue;
        }
      } catch (e) {
        print('❌ JWT_MANAGER: localStorage read failed: $e');
      }
    }
    
    return null;
  }

  /// Store JWT tokens securely
  static Future<void> storeTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userRole,
    required String sessionId,
    bool persistent = false,
  }) async {
    try {
      print('🔐 JWT_MANAGER: Storing tokens...');
      print('🔐 JWT_MANAGER: Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      print('🔐 JWT_MANAGER: Access token length: ${accessToken.length}');
      print('🔐 JWT_MANAGER: User ID: $userId');
      print('🔐 JWT_MANAGER: Persistent session: $persistent');
      
      // Set expiry time only for JWT tokens, not Django tokens
      DateTime? expiryTime;
      if (_isJWTToken(accessToken)) {
        expiryTime = DateTime.now().add(
          Duration(seconds: SecurityConfig.tokenExpiryDuration),
        );
        print('🔐 JWT_MANAGER: JWT token detected, setting expiry: $expiryTime');
      } else {
        print('🔐 JWT_MANAGER: Django token detected, no expiry');
      }

      final futures = [
        _safeWrite(_accessTokenKey, accessToken),
        _safeWrite(_refreshTokenKey, refreshToken),
        _safeWrite(_userIdKey, userId),
        _safeWrite(_userRoleKey, userRole),
        _safeWrite(_sessionIdKey, sessionId),
        _safeWrite(_sessionPersistentKey, persistent.toString()),
      ];
      
      // Only store expiry for JWT tokens
      if (expiryTime != null) {
        futures.add(_safeWrite(_tokenExpiryKey, expiryTime.toIso8601String()));
      }

      await Future.wait(futures);
      
      print('✅ JWT_MANAGER: Tokens stored successfully');
      
      // Immediate verification for web platform
      if (kIsWeb) {
        print('🧪 JWT_MANAGER: Web platform - testing immediate retrieval...');
        try {
          final testToken = await _safeRead(_accessTokenKey);
          if (testToken != null) {
            print('✅ JWT_MANAGER: Immediate verification PASSED - token retrievable');
          } else {
            print('❌ JWT_MANAGER: Immediate verification FAILED - token not retrievable');
          }
        } catch (e) {
          print('❌ JWT_MANAGER: Immediate verification ERROR: $e');
        }
      }

      SecurityConfig.logSecurityEvent('TOKEN_STORED', {
        'userId': userId,
        'role': userRole,
        'sessionId': sessionId,
        'persistent': persistent,
      });
    } catch (e) {
      print('❌ JWT_MANAGER: Token storage error: $e');
      SecurityConfig.logSecurityEvent('TOKEN_STORE_ERROR', {
        'error': e.toString(),
      });
      throw SecurityException('Failed to store authentication tokens');
    }
  }

  /// Retrieve access token
  static Future<String?> getAccessToken() async {
    try {
      print('🔍 JWT_MANAGER: Attempting to retrieve access token...');
      print('🔍 JWT_MANAGER: Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      
      // Additional web debugging
      if (kIsWeb) {
        print('🌐 JWT_MANAGER: Web platform - checking IndexedDB storage...');
      }
      
      final token = await _safeRead(_accessTokenKey);
      
      if (token == null) {
        print('❌ JWT_MANAGER: No access token found in storage');
        if (kIsWeb) {
          print('🌐 JWT_MANAGER: Web storage may not be persisting - checking fallback storages...');
          print('🔍 JWT_MANAGER: Memory storage keys: ${_webFallbackStorage.keys.toList()}');
          try {
            final localStorageKeys = html.window.localStorage.keys.toList();
            print('🔍 JWT_MANAGER: localStorage keys: $localStorageKeys');
          } catch (e) {
            print('❌ JWT_MANAGER: Error reading localStorage keys: $e');
          }
        }
        return null;
      }

      print('✅ JWT_MANAGER: Token found, length: ${token.length}');
      print('🔍 JWT_MANAGER: Token type: ${_isJWTToken(token) ? "JWT" : "Django"}');
      print('🔍 JWT_MANAGER: Token starts with: ${token.substring(0, 20)}...');

      // Only check expiry for JWT tokens, not Django tokens
      if (_isJWTToken(token)) {
        // Check if token is expired
        if (await isTokenExpired()) {
          print('❌ JWT_MANAGER: JWT token is expired, clearing tokens');
          await clearTokens();
          return null;
        }
        print('✅ JWT_MANAGER: JWT token is valid (not expired)');
      } else {
        print('✅ JWT_MANAGER: Django token - no expiry check needed');
      }

      return token;
    } catch (e) {
      print('❌ JWT_MANAGER: Token retrieval error: $e');
      SecurityConfig.logSecurityEvent('TOKEN_RETRIEVAL_ERROR', {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Retrieve refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      SecurityConfig.logSecurityEvent('REFRESH_TOKEN_RETRIEVAL_ERROR', {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Check if access token is expired
  static Future<bool> isTokenExpired() async {
    try {
      final expiryString = await _storage.read(key: _tokenExpiryKey);
      if (expiryString == null) return true;

      final expiry = DateTime.parse(expiryString);
      return DateTime.now().isAfter(expiry);
    } catch (e) {
      return true; // Assume expired if we can't parse
    }
  }

  /// Get user information from stored tokens
  static Future<UserInfo?> getUserInfo() async {
    try {
      final userId = await _storage.read(key: _userIdKey);
      final userRole = await _storage.read(key: _userRoleKey);
      final sessionId = await _storage.read(key: _sessionIdKey);
      final persistentString = await _storage.read(key: _sessionPersistentKey);
      final isPersistent = persistentString == 'true';

      if (userId == null || userRole == null || sessionId == null) {
        return null;
      }

      return UserInfo(
        userId: userId,
        role: UserRole.fromString(userRole),
        sessionId: sessionId,
        isPersistent: isPersistent,
      );
    } catch (e) {
      SecurityConfig.logSecurityEvent('USER_INFO_RETRIEVAL_ERROR', {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Clear all stored tokens
  static Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _accessTokenKey),
        _storage.delete(key: _refreshTokenKey),
        _storage.delete(key: _tokenExpiryKey),
        _storage.delete(key: _userIdKey),
        _storage.delete(key: _userRoleKey),
        _storage.delete(key: _sessionIdKey),
        _storage.delete(key: _sessionPersistentKey),
      ]);

      SecurityConfig.logSecurityEvent('TOKENS_CLEARED', {});
    } catch (e) {
      SecurityConfig.logSecurityEvent('TOKEN_CLEAR_ERROR', {
        'error': e.toString(),
      });
    }
  }

  /// Validate token structure (supports both JWT and Django tokens)
  static bool validateTokenStructure(String token) {
    try {
      // Check if it's a JWT token (3 parts separated by dots)
      final parts = token.split('.');
      if (parts.length == 3) {
        // Validate JWT structure
        final header = _decodeBase64(parts[0]);
        final payload = _decodeBase64(parts[1]);
        jsonDecode(header);
        jsonDecode(payload);
        return true;
      }
      
      // Check if it's a Django token (40-character hex string)
      if (token.length == 40 && RegExp(r'^[a-f0-9]+$').hasMatch(token)) {
        return true;
      }
      
      // Check if it's a longer token (like our generated ones)
      if (token.length >= 32 && token.length <= 128) {
        return true;
      }
      
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Decode JWT payload (without signature verification - for client-side info only)
  /// Returns null for Django tokens since they don't contain payload data
  static Map<String, dynamic>? decodeTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        // JWT token - decode payload
        final payload = _decodeBase64(parts[1]);
        return jsonDecode(payload) as Map<String, dynamic>;
      }
      
      // Django token - no payload to decode
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if user has required role
  static Future<bool> hasRole(UserRole requiredRole) async {
    final userInfo = await getUserInfo();
    if (userInfo == null) return false;

    return userInfo.role.level >= requiredRole.level;
  }

  /// Check if user has specific permission
  static Future<bool> hasPermission(String permission) async {
    final userInfo = await getUserInfo();
    if (userInfo == null) return false;

    return userInfo.role.permissions.contains(permission);
  }

  /// Generate session ID
  static String generateSessionId() {
    return SecurityConfig.generateSecureToken(32);
  }

  /// Refresh access token using refresh token
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      // In a real implementation, this would call the backend API
      // For now, we'll simulate token refresh
      SecurityConfig.logSecurityEvent('TOKEN_REFRESH_ATTEMPTED', {});
      
      // This should be replaced with actual API call
      return false; // Indicate that refresh failed (no backend implementation)
    } catch (e) {
      SecurityConfig.logSecurityEvent('TOKEN_REFRESH_ERROR', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Validate token expiry and auto-refresh if needed
  static Future<bool> ensureValidToken() async {
    try {
      final accessToken = await getAccessToken();
      
      if (accessToken == null) {
        return false;
      }

      // For JWT tokens, check expiry and refresh if needed
      if (_isJWTToken(accessToken)) {
        if (await isTokenExpired()) {
          return await refreshAccessToken();
        }
      }
      // Django tokens don't expire, so they're always valid if they exist

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if current session is persistent (Google Auth)
  static Future<bool> isSessionPersistent() async {
    try {
      final persistentString = await _storage.read(key: _sessionPersistentKey);
      return persistentString == 'true';
    } catch (e) {
      return false;
    }
  }

  static String _decodeBase64(String base64) {
    // Add padding if needed
    String normalized = base64.replaceAll('-', '+').replaceAll('_', '/');
    while (normalized.length % 4 != 0) {
      normalized += '=';
    }
    return utf8.decode(base64Decode(normalized));
  }
}

class UserInfo {
  final String userId;
  final UserRole role;
  final String sessionId;
  final bool isPersistent;

  const UserInfo({
    required this.userId,
    required this.role,
    required this.sessionId,
    this.isPersistent = false,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'role': role.name,
    'sessionId': sessionId,
    'isPersistent': isPersistent,
  };

  @override
  String toString() => 'UserInfo(userId: $userId, role: ${role.name}, sessionId: $sessionId, persistent: $isPersistent)';
}

enum UserRole {
  guest(0, 'guest', []),
  member(1, 'member', ['view_profile', 'update_profile']),
  trainer(2, 'trainer', ['view_profile', 'update_profile', 'view_members', 'manage_sessions']),
  admin(3, 'admin', ['view_profile', 'update_profile', 'view_members', 'manage_sessions', 'view_reports', 'manage_trainers']),
  superAdmin(4, 'super_admin', ['*']); // All permissions

  const UserRole(this.level, this.name, this.permissions);

  final int level;
  final String name;
  final List<String> permissions;

  static UserRole fromString(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'guest':
        return UserRole.guest;
      case 'member':
        return UserRole.member;
      case 'trainer':
        return UserRole.trainer;
      case 'admin':
        return UserRole.admin;
      case 'super_admin':
        return UserRole.superAdmin;
      default:
        return UserRole.guest;
    }
  }

  bool hasPermission(String permission) {
    if (permissions.contains('*')) return true;
    return permissions.contains(permission);
  }
}

class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}