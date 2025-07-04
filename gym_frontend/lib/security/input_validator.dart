import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'security_config.dart';

class InputValidator {
  // Email validation with comprehensive regex
  static const String _emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // Phone number validation (international format)
  static const String _phoneRegex = r'^\+?[1-9]\d{1,14}$';
  
  // Name validation (letters, spaces, hyphens, apostrophes)
  static const String _nameRegex = r"^[a-zA-Z\s\-']{2,50}$";
  
  // Alphanumeric with common safe characters
  static const String _alphanumericRegex = r'^[a-zA-Z0-9\s\-_.]{1,100}$';
  
  // SQL injection patterns
  static const List<String> _sqlInjectionPatterns = [
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)",
    r"(--|#|/\*|\*/)",
    r"(\b(OR|AND)\s+\d+\s*=\s*\d+)",
    r"(\bUNION\s+SELECT\b)",
    r"(\b(EXEC|EXECUTE)\s*\()",
    r"(;|\|\||&&)",
  ];
  
  // XSS patterns
  static const List<String> _xssPatterns = [
    r"<script[^>]*>.*?</script>",
    r"javascript:",
    r"on\w+\s*=",
    r"<iframe[^>]*>",
    r"<object[^>]*>",
    r"<embed[^>]*>",
    r"<link[^>]*>",
    r"<meta[^>]*>",
  ];
  
  // Command injection patterns
  static const List<String> _commandInjectionPatterns = [
    r"[;&|`]",
    r"\$\(",
    r"<\(",
    r">\(",
    r"\.\./",
    r"~/",
  ];

  /// Validate email address
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult(false, 'Email is required');
    }
    
    if (email.length > 254) {
      return ValidationResult(false, 'Email is too long');
    }
    
    if (!RegExp(_emailRegex).hasMatch(email)) {
      return ValidationResult(false, 'Please enter a valid email address');
    }
    
    // Check for potentially dangerous patterns
    if (_containsMaliciousPatterns(email)) {
      return ValidationResult(false, 'Invalid email format');
    }
    
    return ValidationResult(true, 'Valid email');
  }

  /// Validate password with strong requirements
  static ValidationResult validatePassword(String password) {
    if (password.isEmpty) {
      return ValidationResult(false, 'Password is required');
    }
    
    if (password.length < SecurityConfig.minPasswordLength) {
      return ValidationResult(false, 'Password must be at least ${SecurityConfig.minPasswordLength} characters long');
    }
    
    if (password.length > SecurityConfig.maxPasswordLength) {
      return ValidationResult(false, 'Password is too long');
    }
    
    if (SecurityConfig.requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      return ValidationResult(false, 'Password must contain at least one uppercase letter');
    }
    
    if (SecurityConfig.requireLowercase && !password.contains(RegExp(r'[a-z]'))) {
      return ValidationResult(false, 'Password must contain at least one lowercase letter');
    }
    
    if (SecurityConfig.requireNumbers && !password.contains(RegExp(r'[0-9]'))) {
      return ValidationResult(false, 'Password must contain at least one number');
    }
    
    if (SecurityConfig.requireSpecialChars && !password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return ValidationResult(false, 'Password must contain at least one special character');
    }
    
    // Check for common weak passwords
    if (_isCommonPassword(password)) {
      return ValidationResult(false, 'Password is too common. Please choose a stronger password');
    }
    
    return ValidationResult(true, 'Strong password');
  }

  /// Validate phone number
  static ValidationResult validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return ValidationResult(false, 'Phone number is required');
    }
    
    // Remove common formatting characters
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    if (!RegExp(_phoneRegex).hasMatch(cleanPhone)) {
      return ValidationResult(false, 'Please enter a valid phone number');
    }
    
    if (_containsMaliciousPatterns(cleanPhone)) {
      return ValidationResult(false, 'Invalid phone number format');
    }
    
    return ValidationResult(true, 'Valid phone number');
  }

  /// Validate name fields
  static ValidationResult validateName(String name, {String fieldName = 'Name'}) {
    if (name.isEmpty) {
      return ValidationResult(false, '$fieldName is required');
    }
    
    if (name.length < 2) {
      return ValidationResult(false, '$fieldName must be at least 2 characters long');
    }
    
    if (!RegExp(_nameRegex).hasMatch(name)) {
      return ValidationResult(false, '$fieldName contains invalid characters');
    }
    
    if (_containsMaliciousPatterns(name)) {
      return ValidationResult(false, 'Invalid $fieldName format');
    }
    
    return ValidationResult(true, 'Valid $fieldName');
  }

  /// Validate and sanitize general text input
  static ValidationResult validateTextInput(String input, {
    int maxLength = 1000,
    bool allowEmpty = false,
    String fieldName = 'Input',
  }) {
    if (!allowEmpty && input.isEmpty) {
      return ValidationResult(false, '$fieldName is required');
    }
    
    if (input.length > maxLength) {
      return ValidationResult(false, '$fieldName is too long (max $maxLength characters)');
    }
    
    if (_containsMaliciousPatterns(input)) {
      return ValidationResult(false, 'Invalid characters detected in $fieldName');
    }
    
    return ValidationResult(true, 'Valid $fieldName');
  }

  /// Validate numeric input
  static ValidationResult validateNumericInput(String input, {
    double? min,
    double? max,
    bool allowDecimals = true,
    String fieldName = 'Number',
  }) {
    if (input.isEmpty) {
      return ValidationResult(false, '$fieldName is required');
    }
    
    final regex = allowDecimals ? r'^\d+(\.\d+)?$' : r'^\d+$';
    if (!RegExp(regex).hasMatch(input)) {
      return ValidationResult(false, 'Please enter a valid $fieldName');
    }
    
    final value = double.tryParse(input);
    if (value == null) {
      return ValidationResult(false, 'Invalid $fieldName format');
    }
    
    if (min != null && value < min) {
      return ValidationResult(false, '$fieldName must be at least $min');
    }
    
    if (max != null && value > max) {
      return ValidationResult(false, '$fieldName must not exceed $max');
    }
    
    return ValidationResult(true, 'Valid $fieldName');
  }

  /// Sanitize input by removing/escaping dangerous characters
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('&', '&amp;')
        .replaceAll('\n', ' ')
        .replaceAll('\r', ' ')
        .trim();
  }

  /// Check for malicious patterns
  static bool _containsMaliciousPatterns(String input) {
    final lowercaseInput = input.toLowerCase();
    
    // Check SQL injection patterns
    for (final pattern in _sqlInjectionPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowercaseInput)) {
        SecurityConfig.logSecurityEvent('SQL_INJECTION_ATTEMPT', {
          'pattern': pattern,
          'inputLength': input.length,
        });
        return true;
      }
    }
    
    // Check XSS patterns
    for (final pattern in _xssPatterns) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(lowercaseInput)) {
        SecurityConfig.logSecurityEvent('XSS_ATTEMPT', {
          'pattern': pattern,
          'inputLength': input.length,
        });
        return true;
      }
    }
    
    // Check command injection patterns
    for (final pattern in _commandInjectionPatterns) {
      if (RegExp(pattern).hasMatch(input)) {
        SecurityConfig.logSecurityEvent('COMMAND_INJECTION_ATTEMPT', {
          'pattern': pattern,
          'inputLength': input.length,
        });
        return true;
      }
    }
    
    return false;
  }

  /// Check if password is commonly used
  static bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', '12345678', '111111', '1234567890',
      'admin', 'letmein', 'welcome', 'monkey', '1234567',
      'password1', 'admin123', 'welcome123', 'guest', 'user',
    ];
    
    return commonPasswords.contains(password.toLowerCase());
  }

  /// Validate QR code format and content
  static ValidationResult validateQRCode(String qrCode) {
    if (qrCode.isEmpty) {
      return ValidationResult(false, 'QR code is empty');
    }
    
    if (qrCode.length > 1000) {
      return ValidationResult(false, 'QR code is too long');
    }
    
    // Check for malicious patterns
    if (_containsMaliciousPatterns(qrCode)) {
      return ValidationResult(false, 'Invalid QR code format');
    }
    
    // Validate QR code format (should be JSON or specific format)
    try {
      // Try to parse as JSON first
      final decoded = jsonDecode(qrCode);
      if (decoded is Map<String, dynamic>) {
        if (decoded.containsKey('memberId') && decoded.containsKey('timestamp')) {
          // Validate timestamp (should be within last 5 minutes for security)
          final timestamp = DateTime.tryParse(decoded['timestamp'] ?? '');
          if (timestamp == null || DateTime.now().difference(timestamp).inMinutes > 5) {
            return ValidationResult(false, 'QR code has expired');
          }
          return ValidationResult(true, 'Valid QR code');
        }
      }
    } catch (e) {
      // Not JSON, check if it's a simple member ID
      if (RegExp(r'^\d{1,10}$').hasMatch(qrCode)) {
        return ValidationResult(true, 'Valid member ID QR code');
      }
    }
    
    return ValidationResult(false, 'Invalid QR code format');
  }

  /// Validate file upload
  static ValidationResult validateFileUpload(String fileName, int fileSize, List<String> allowedExtensions) {
    if (fileName.isEmpty) {
      return ValidationResult(false, 'File name is required');
    }
    
    // Check file extension
    final extension = fileName.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult(false, 'File type not allowed. Allowed types: ${allowedExtensions.join(', ')}');
    }
    
    // Check file size (max 10MB)
    if (fileSize > 10 * 1024 * 1024) {
      return ValidationResult(false, 'File size too large. Maximum size is 10MB');
    }
    
    // Check for malicious file names
    if (_containsMaliciousPatterns(fileName)) {
      return ValidationResult(false, 'Invalid file name');
    }
    
    return ValidationResult(true, 'Valid file');
  }
}

class ValidationResult {
  final bool isValid;
  final String message;
  
  const ValidationResult(this.isValid, this.message);
  
  @override
  String toString() => 'ValidationResult(isValid: $isValid, message: $message)';
}