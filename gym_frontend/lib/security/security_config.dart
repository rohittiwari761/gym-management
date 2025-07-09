import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class SecurityConfig {
  // Environment-based configuration
  static const bool _isProduction = bool.fromEnvironment('dart.vm.product');
  
  // Production URL
  static const String _prodApiUrl = 'https://gym-management-production-4343.up.railway.app/api';
  
  // Local development URLs (fallback only)
  static const String _localhostApiUrl = 'http://localhost:8000/api';
  static const String _localApiUrl = 'http://127.0.0.1:8000/api';
  static const String _macNetworkApiUrl = 'http://192.168.1.14:8000/api';
  
  // Use production URL for deployment
  static String get apiUrl {
    return _prodApiUrl;
  }
  
  /// Alternative local URLs to try if primary fails (ordered by likelihood of success)
  static List<String> get localFallbackUrls => [
    'http://localhost:8000/api', // iOS Simulator compatible (first fallback)
    'http://127.0.0.1:8000/api', // Direct localhost 
    'http://192.168.1.13:8000/api', // Previous IP (if changed)
    'http://192.168.1.6:8000/api', // Older IP (if changed)
    'http://192.168.1.1:8000/api', // Router gateway IP
    'http://10.0.0.1:8000/api', // Alternative gateway
    'http://172.16.0.1:8000/api', // Alternative private IP
  ];
  
  
  // Security Settings
  static const int tokenExpiryDuration = 3600; // 1 hour in seconds
  static const int refreshTokenExpiryDuration = 604800; // 7 days in seconds
  static const int maxLoginAttempts = 5;
  static const int loginCooldownSeconds = 300; // 5 minutes
  
  // Encryption Settings
  static const int saltLength = 32;
  static const int keyLength = 32;
  static const int ivLength = 16;
  
  // Password Policy
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const bool requireUppercase = true;
  static const bool requireLowercase = true;
  static const bool requireNumbers = true;
  static const bool requireSpecialChars = true;
  
  // Session Management
  static const int sessionTimeoutMinutes = 30;
  static const int maxConcurrentSessions = 3;
  
  // Rate Limiting
  static const int maxRequestsPerMinute = 60;
  static const int maxRequestsPerHour = 1000;
  
  // Security Headers
  static Map<String, String> get securityHeaders => {
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'X-XSS-Protection': '1; mode=block',
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'Content-Security-Policy': "default-src 'self'; script-src 'self'",
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'Permissions-Policy': 'geolocation=(), microphone=(), camera=()',
  };
  
  // Certificate Pinning (SHA-256 hashes of expected certificates)
  static const List<String> certificatePins = [
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=', // Replace with actual cert hashes
    'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=', // Backup certificate
  ];
  
  // Generate secure random string
  static String generateSecureToken([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // Generate salt for password hashing
  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(saltLength, (i) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
  
  // Hash password with salt
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Verify password
  static bool verifyPassword(String password, String salt, String hashedPassword) {
    return hashPassword(password, salt) == hashedPassword;
  }
  
  // Generate CSRF token
  static String generateCSRFToken() {
    return generateSecureToken(64);
  }
  
  // Validate API response integrity
  static bool validateResponseIntegrity(String response, String signature, String key) {
    final hmac = Hmac(sha256, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(response));
    return digest.toString() == signature;
  }
  
  // Security logging (without sensitive data)
  static void logSecurityEvent(String event, Map<String, dynamic> metadata) {
    // In production, send to secure logging service
    // For now, events are logged silently
  }
  
  // Sanitize log data
  static Map<String, dynamic> sanitizeLogData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    final sensitiveKeys = ['password', 'token', 'email', 'phone', 'address'];
    
    for (final entry in data.entries) {
      if (sensitiveKeys.contains(entry.key.toLowerCase())) {
        sanitized[entry.key] = '[REDACTED]';
      } else {
        sanitized[entry.key] = entry.value;
      }
    }
    return sanitized;
  }
}