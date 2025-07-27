import 'dart:html' as html;

/// Web-specific implementation of Brave browser detection
class BraveAuthWebImpl {
  /// Detect if user is using Brave browser or other privacy-focused browsers
  static bool isBraveBrowser() {
    try {
      final userAgent = html.window.navigator.userAgent.toLowerCase();
      final isBrave = userAgent.contains('brave') || 
                     html.window.navigator.userAgent.contains('Brave');
      
      // Also check for other privacy indicators
      final hasStrictPrivacy = userAgent.contains('duckduckgo') ||
                              userAgent.contains('tor') ||
                              userAgent.contains('privacy');
      
      print('🔍 BRAVE_AUTH: User agent: $userAgent');
      print('🔍 BRAVE_AUTH: Is Brave: $isBrave');
      print('🔍 BRAVE_AUTH: Has strict privacy: $hasStrictPrivacy');
      
      return isBrave || hasStrictPrivacy;
    } catch (e) {
      print('❌ BRAVE_AUTH: Error detecting browser: $e');
      return false;
    }
  }

  /// Check if Google services are blocked
  static Future<bool> isGoogleBlocked() async {
    try {
      print('🔍 BRAVE_AUTH: Testing Google connectivity...');
      
      // Test if we can reach Google's basic endpoints
      final testUrls = [
        'https://accounts.google.com/gsi/client',
        'https://www.googleapis.com/auth/userinfo.email',
      ];
      
      for (final url in testUrls) {
        try {
          final img = html.ImageElement();
          final completer = Future<bool>(() async {
            return await Future.any([
              Future.delayed(Duration(seconds: 2), () => false),
              Future(() async {
                img.src = url;
                await img.onLoad.first;
                return true;
              }),
            ]);
          });
          
          final canReach = await completer;
          if (!canReach) {
            print('❌ BRAVE_AUTH: Cannot reach $url');
            return true; // Google is blocked
          }
        } catch (e) {
          print('❌ BRAVE_AUTH: Error testing $url: $e');
          return true; // Assume blocked on error
        }
      }
      
      print('✅ BRAVE_AUTH: Google services appear accessible');
      return false;
    } catch (e) {
      print('❌ BRAVE_AUTH: Error testing Google connectivity: $e');
      return true; // Assume blocked on error
    }
  }

  /// Create a direct OAuth URL for manual authentication
  static String createDirectOAuthUrl() {
    final clientId = '818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g.apps.googleusercontent.com';
    final redirectUri = html.window.location.origin;
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
  }

  /// Open Google OAuth in a new tab
  static void openGoogleAuthInNewTab() {
    try {
      final oauthUrl = createDirectOAuthUrl();
      html.window.open(oauthUrl, '_blank');
      print('✅ BRAVE_AUTH: Opened OAuth in new tab');
    } catch (e) {
      print('❌ BRAVE_AUTH: Error opening OAuth tab: $e');
    }
  }

  /// Handle OAuth callback when user returns from Google
  static Map<String, String>? handleOAuthCallback() {
    try {
      final url = html.window.location.href;
      final uri = Uri.parse(url);
      
      if (uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code']!;
        final state = uri.queryParameters['state'];
        
        print('✅ BRAVE_AUTH: Received OAuth code: ${code.substring(0, 10)}...');
        print('✅ BRAVE_AUTH: State: $state');
        
        return {
          'code': code,
          'state': state ?? '',
        };
      }
      
      if (uri.queryParameters.containsKey('error')) {
        final error = uri.queryParameters['error']!;
        print('❌ BRAVE_AUTH: OAuth error: $error');
        return {'error': error};
      }
      
      return null;
    } catch (e) {
      print('❌ BRAVE_AUTH: Error handling OAuth callback: $e');
      return {'error': e.toString()};
    }
  }

  /// Get the current window origin
  static String getWindowOrigin() {
    return html.window.location.origin;
  }

  /// Check if we're currently handling an OAuth callback
  static bool isOAuthCallback() {
    try {
      final url = html.window.location.href;
      final uri = Uri.parse(url);
      return uri.queryParameters.containsKey('code') || 
             uri.queryParameters.containsKey('error');
    } catch (e) {
      return false;
    }
  }

  /// Clean OAuth parameters from URL after handling
  static void cleanOAuthUrl() {
    try {
      final url = html.window.location.href;
      final uri = Uri.parse(url);
      
      if (uri.queryParameters.containsKey('code') || 
          uri.queryParameters.containsKey('error') ||
          uri.queryParameters.containsKey('state')) {
        
        // Remove OAuth parameters
        final cleanedParams = Map<String, String>.from(uri.queryParameters);
        cleanedParams.remove('code');
        cleanedParams.remove('error');
        cleanedParams.remove('state');
        cleanedParams.remove('scope');
        
        // Build clean URL
        final cleanUri = uri.replace(queryParameters: cleanedParams.isEmpty ? null : cleanedParams);
        html.window.history.replaceState(null, '', cleanUri.toString());
        
        print('✅ BRAVE_AUTH: Cleaned OAuth parameters from URL');
      }
    } catch (e) {
      print('❌ BRAVE_AUTH: Error cleaning OAuth URL: $e');
    }
  }

  /// Generate a random state parameter for OAuth security
  static String _generateRandomState() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    return chars * 3 + random.toString();
  }
}