import 'package:flutter/foundation.dart';

/// Application configuration management
/// Handles environment-specific settings and URLs
class AppConfig {
  static const String _version = '1.0.0';
  static const String _buildNumber = '1';
  
  // Environment configuration
  static const String _defaultEnvironment = kDebugMode ? 'development' : 'production';
  static String _currentEnvironment = _defaultEnvironment;
  
  // API Configuration
  static const Map<String, ApiConfig> _apiConfigs = {
    'production': ApiConfig(
      baseUrl: 'https://gym-management-production-2168.up.railway.app/api',
      timeout: Duration(seconds: 30),
      retryAttempts: 3,
      fallbackUrls: [
        'https://gym-management-production.up.railway.app/api',
        'https://gym-backend-production.up.railway.app/api',
      ],
    ),
    'staging': ApiConfig(
      baseUrl: 'https://gym-management-staging.up.railway.app/api',
      timeout: Duration(seconds: 30),
      retryAttempts: 2,
      fallbackUrls: [],
    ),
    'development': ApiConfig(
      baseUrl: 'http://localhost:8000/api',
      timeout: Duration(seconds: 15),
      retryAttempts: 1,
      fallbackUrls: [
        'http://192.168.1.7:8000/api',
      ],
    ),
  };
  
  // Google OAuth Configuration
  static const Map<String, GoogleConfig> _googleConfigs = {
    'production': GoogleConfig(
      webClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
      iOSClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
      androidClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
    ),
    'staging': GoogleConfig(
      webClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
      iOSClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
      androidClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
    ),
    'development': GoogleConfig(
      webClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
      iOSClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
      androidClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
    ),
  };
  
  // Getters
  static String get version => _version;
  static String get buildNumber => _buildNumber;
  static String get environment => _currentEnvironment;
  static bool get isProduction => _currentEnvironment == 'production';
  static bool get isDevelopment => _currentEnvironment == 'development';
  static bool get isStaging => _currentEnvironment == 'staging';
  
  // API Configuration
  static ApiConfig get apiConfig => _apiConfigs[_currentEnvironment] ?? _apiConfigs['production']!;
  static GoogleConfig get googleConfig => _googleConfigs[_currentEnvironment] ?? _googleConfigs['production']!;
  
  // Security Configuration
  static const SecurityConfig securityConfig = SecurityConfig(
    enableSSLPinning: true,
    enableRequestValidation: true,
    enableResponseValidation: true,
    maxRetryAttempts: 3,
    requestTimeout: Duration(seconds: 30),
  );
  
  /// Set environment (for testing or different deployments)
  static void setEnvironment(String env) {
    if (_apiConfigs.containsKey(env)) {
      _currentEnvironment = env;
      print('📱 AppConfig: Environment set to $env');
    } else {
      print('❌ AppConfig: Invalid environment $env');
    }
  }
  
  /// Get platform-specific Google Client ID
  static String getGoogleClientId() {
    final config = googleConfig;
    if (kIsWeb) {
      return config.webClientId;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return config.iOSClientId;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return config.androidClientId;
    } else {
      return config.webClientId; // Fallback
    }
  }
  
  /// Validate configuration
  static bool validateConfiguration() {
    try {
      // Check API configuration
      final api = apiConfig;
      if (api.baseUrl.isEmpty) {
        print('❌ AppConfig: Invalid API base URL');
        return false;
      }
      
      // Check Google configuration
      final google = googleConfig;
      if (google.webClientId.isEmpty) {
        print('❌ AppConfig: Invalid Google client ID');
        return false;
      }
      
      print('✅ AppConfig: Configuration validated successfully');
      return true;
    } catch (e) {
      print('❌ AppConfig: Configuration validation failed: $e');
      return false;
    }
  }
  
  /// Get debug information
  static Map<String, dynamic> getDebugInfo() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'environment': environment,
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'isDebug': kDebugMode,
      'apiBaseUrl': apiConfig.baseUrl,
      'googleClientId': getGoogleClientId(),
      'configValid': validateConfiguration(),
    };
  }
}

/// API Configuration class
class ApiConfig {
  final String baseUrl;
  final Duration timeout;
  final int retryAttempts;
  final List<String> fallbackUrls;
  
  const ApiConfig({
    required this.baseUrl,
    required this.timeout,
    required this.retryAttempts,
    required this.fallbackUrls,
  });
}

/// Google OAuth Configuration class
class GoogleConfig {
  final String webClientId;
  final String iOSClientId;
  final String androidClientId;
  
  const GoogleConfig({
    required this.webClientId,
    required this.iOSClientId,
    required this.androidClientId,
  });
}

/// Security Configuration class
class SecurityConfig {
  final bool enableSSLPinning;
  final bool enableRequestValidation;
  final bool enableResponseValidation;
  final int maxRetryAttempts;
  final Duration requestTimeout;
  
  const SecurityConfig({
    required this.enableSSLPinning,
    required this.enableRequestValidation,
    required this.enableResponseValidation,
    required this.maxRetryAttempts,
    required this.requestTimeout,
  });
}