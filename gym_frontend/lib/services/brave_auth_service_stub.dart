/// Stub implementation for non-web platforms
class BraveAuthWebImpl {
  /// Detect if user is using Brave browser (always false on non-web)
  static bool isBraveBrowser() {
    return false;
  }

  /// Check if Google services are blocked (always false on non-web)
  static Future<bool> isGoogleBlocked() async {
    return false;
  }

  /// Create a direct OAuth URL (not available on non-web)
  static String createDirectOAuthUrl() {
    return '';
  }

  /// Open Google OAuth in a new tab (no-op on non-web)
  static void openGoogleAuthInNewTab() {
    // No-op on non-web platforms
  }

  /// Handle OAuth callback (always null on non-web)
  static Map<String, String>? handleOAuthCallback() {
    return null;
  }

  /// Get the current window origin (empty on non-web)
  static String getWindowOrigin() {
    return '';
  }

  /// Check if we're currently handling an OAuth callback (always false on non-web)
  static bool isOAuthCallback() {
    return false;
  }

  /// Clean OAuth parameters from URL (no-op on non-web)
  static void cleanOAuthUrl() {
    // No-op on non-web platforms
  }
}