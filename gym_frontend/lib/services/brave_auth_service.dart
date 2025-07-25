import 'package:flutter/foundation.dart';
import '../security/secure_http_client.dart';

class BraveAuthService {
  static final BraveAuthService _instance = BraveAuthService._internal();
  factory BraveAuthService() => _instance;
  BraveAuthService._internal();

  final SecureHttpClient _httpClient = SecureHttpClient();

  /// Detect if user is using Brave browser or other privacy-focused browsers
  /// Note: Only works on web platform, returns false on mobile
  static bool isBraveBrowser() {
    if (!kIsWeb) return false;
    
    try {
      // For now, we'll return false on non-web platforms
      // This functionality requires dart:html which is not available on iOS/Android
      return false;
    } catch (e) {
      print('❌ BRAVE_AUTH: Error detecting browser: $e');
      return false;
    }
  }

  /// Check if Google services are blocked
  /// Note: Only works on web platform, returns false on mobile
  static Future<bool> isGoogleBlocked() async {
    if (!kIsWeb) return false;
    
    try {
      // For now, we'll return false on non-web platforms
      // This functionality requires dart:html which is not available on iOS/Android
      return false;
    } catch (e) {
      print('❌ BRAVE_AUTH: Error testing Google connectivity: $e');
      return true; // Assume blocked on error
    }
  }

  /// Create a direct OAuth URL for manual authentication
  /// Note: Only works on web platform, returns empty string on mobile
  static String createDirectOAuthUrl() {
    if (!kIsWeb) return '';
    
    try {
      final clientId = '818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g.apps.googleusercontent.com';
      // For non-web platforms, we can't get the window location
      // This would need to be provided by the calling code
      final redirectUri = ''; // Would need to be set appropriately for the platform
      final scope = 'openid email profile';
      final state = _generateRandomState();
      
      final oauthUrl = 'https://accounts.google.com/o/oauth2/v2/auth'
          '?client_id=$clientId'
          '&redirect_uri=$redirectUri'
          '&scope=$scope'
          '&response_type=code'
          '&state=$state'
          '&access_type=offline'
          '&prompt=select_account';
      
      print('🔗 BRAVE_AUTH: Generated OAuth URL: $oauthUrl');
      return oauthUrl;
    } catch (e) {
      print('❌ BRAVE_AUTH: Error creating OAuth URL: $e');
      return '';
    }
  }

  /// Open Google OAuth in a new tab (works better than popups in Brave)
  /// Note: Only works on web platform, does nothing on mobile
  static void openGoogleAuthInNewTab() {
    if (!kIsWeb) return;
    
    try {
      // This functionality requires dart:html which is not available on iOS/Android
      // Mobile apps would typically use the google_sign_in package instead
      print('❌ BRAVE_AUTH: OAuth tab opening not supported on this platform');
    } catch (e) {
      print('❌ BRAVE_AUTH: Error opening OAuth tab: $e');
    }
  }

  /// Handle OAuth callback when user returns from Google
  /// Note: Only works on web platform, returns null on mobile
  static Map<String, String>? handleOAuthCallback() {
    if (!kIsWeb) return null;
    
    try {
      // This functionality requires dart:html which is not available on iOS/Android
      // Mobile apps would handle OAuth differently through deep links or custom schemes
      return null;
    } catch (e) {
      print('❌ BRAVE_AUTH: Error handling OAuth callback: $e');
      return {'error': e.toString()};
    }
  }

  /// Exchange OAuth code for tokens via backend
  Future<Map<String, dynamic>> exchangeCodeForTokens(String code) async {
    try {
      print('🔄 BRAVE_AUTH: Exchanging OAuth code for tokens...');
      
      // For non-web platforms, we don't have window.location.origin
      // The redirect URI would need to be provided by the calling code
      String redirectUri = '';
      
      final response = await _httpClient.post(
        'auth/google-oauth/',
        body: {
          'code': code,
          'redirect_uri': redirectUri,
        },
        requireAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        print('✅ BRAVE_AUTH: Token exchange successful');
        return {
          'success': true,
          ...response.data as Map<String, dynamic>,
        };
      } else {
        print('❌ BRAVE_AUTH: Token exchange failed: ${response.errorMessage}');
        return {
          'success': false,
          'error': response.errorMessage ?? 'Token exchange failed',
        };
      }
    } catch (e) {
      print('❌ BRAVE_AUTH: Exception during token exchange: $e');
      return {
        'success': false,
        'error': 'Network error during authentication: $e',
      };
    }
  }

  /// Generate a random state parameter for OAuth security
  static String _generateRandomState() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return chars * 3 + random.toString();
  }

  /// Check if we're currently handling an OAuth callback
  /// Note: Only works on web platform, returns false on mobile
  static bool isOAuthCallback() {
    if (!kIsWeb) return false;
    
    try {
      // This functionality requires dart:html which is not available on iOS/Android
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Clean OAuth parameters from URL after handling
  /// Note: Only works on web platform, does nothing on mobile
  static void cleanOAuthUrl() {
    if (!kIsWeb) return;
    
    try {
      // This functionality requires dart:html which is not available on iOS/Android
      print('❌ BRAVE_AUTH: URL cleaning not supported on this platform');
    } catch (e) {
      print('❌ BRAVE_AUTH: Error cleaning OAuth URL: $e');
    }
  }
}