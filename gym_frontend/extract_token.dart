// Add this temporary function to your Flutter app for token extraction
// You can add this to any screen and call it from a button

import 'lib/security/jwt_manager.dart';

Future<void> extractTokenForTesting() async {
  try {
    final token = await JWTManager.getAccessToken();
    if (token != null) {
      print('🔑 CURRENT_TOKEN_FOR_POSTMAN: $token');
      print('📋 Copy this token for Postman testing:');
      print('Authorization: Token $token');
    } else {
      print('❌ No token found - user might not be logged in');
    }
  } catch (e) {
    print('💥 Error extracting token: $e');
  }
}

// Alternative: Get token with platform info
Future<void> extractTokenWithDetails() async {
  try {
    final token = await JWTManager.getAccessToken();
    final isValid = await JWTManager.hasValidToken();
    final sessionPersistent = await JWTManager.isSessionPersistent();
    
    print('🔑 TOKEN DETAILS FOR DEBUGGING:');
    print('Token: ${token ?? "NULL"}');
    print('Valid: $isValid');
    print('Persistent Session: $sessionPersistent');
    print('Token Length: ${token?.length ?? 0}');
    
    if (token != null) {
      print('📋 FOR POSTMAN:');
      print('Authorization: Token $token');
    }
  } catch (e) {
    print('💥 Error: $e');
  }
}