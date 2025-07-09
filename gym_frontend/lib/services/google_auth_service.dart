import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import '../security/security_config.dart';
import '../security/secure_http_client.dart';
import 'auth_service.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Use the iOS client ID that matches GoogleService-Info.plist
    serverClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
    // Force account picker
    forceCodeForRefreshToken: true,
  );

  final SecureHttpClient _httpClient = SecureHttpClient();

  /// Initialize Google Sign-In
  void initialize() {
    try {
      _httpClient.initialize();
      
      // Pre-initialize Google Sign-In to catch any configuration issues early
      _googleSignIn.signInSilently().catchError((error) {
        print('🔑 GOOGLE AUTH: Silent sign-in failed (this is normal): $error');
        return null;
      });
      
      SecurityConfig.logSecurityEvent('GOOGLE_AUTH_SERVICE_INITIALIZED', {});
      print('🔑 GOOGLE AUTH: Service initialized successfully');
    } catch (e) {
      print('💥 GOOGLE AUTH: Error during initialization: $e');
      SecurityConfig.logSecurityEvent('GOOGLE_AUTH_INIT_ERROR', {
        'error': e.toString(),
      });
    }
  }

  /// Check and restore previous Google Sign-In session
  Future<Map<String, dynamic>?> restorePreviousSession() async {
    try {
      print('🔄 GOOGLE AUTH: Checking for previous Google session...');
      
      // Check if user was previously signed in
      final isSignedIn = await _googleSignIn.isSignedIn();
      if (!isSignedIn) {
        print('🔑 GOOGLE AUTH: No previous Google session found');
        return null;
      }

      // Try to restore the session
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        print('🔑 GOOGLE AUTH: Silent sign-in returned null');
        return null;
      }

      print('🔑 GOOGLE AUTH: Previous session restored for: ${googleUser.email}');
      
      // Get fresh authentication token
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        print('⚠️ GOOGLE AUTH: No ID token in restored session');
        return null;
      }

      // Authenticate with backend using restored token
      final backendResult = await _authenticateWithBackend(googleAuth.idToken!);
      
      if (backendResult['success']) {
        print('✅ GOOGLE AUTH: Previous session successfully restored and authenticated');
        SecurityConfig.logSecurityEvent('GOOGLE_SESSION_RESTORED', {
          'email': googleUser.email,
        });
        return backendResult;
      } else {
        print('❌ GOOGLE AUTH: Backend authentication failed for restored session');
        // Clear the invalid session
        await _googleSignIn.signOut();
        return null;
      }
    } catch (e) {
      print('💥 GOOGLE AUTH: Error restoring previous session: $e');
      SecurityConfig.logSecurityEvent('GOOGLE_SESSION_RESTORE_ERROR', {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Sign in with Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      SecurityConfig.logSecurityEvent('GOOGLE_SIGNIN_INITIATED', {});

      // Check if running in simulator (Google Sign-In has issues in iOS simulator)
      try {
        bool isAvailable = await _googleSignIn.isSignedIn();
      } catch (e) {
        // Continue anyway
      }

      // Check platform and configuration
      if (!await _isGoogleSignInConfigured()) {
        return {
          'success': false,
          'error': 'Google Sign-In is not properly configured. Please check GoogleService-Info.plist for iOS or google-services.json for Android.',
        };
      }

      // Start Google Sign-In process with enhanced error handling
      GoogleSignInAccount? googleUser;
      
      try {
        googleUser = await _googleSignIn.signIn();
      } catch (error) {
        
        // Handle specific iOS simulator issues
        if (error.toString().contains('simulator') || 
            error.toString().contains('Simulator') ||
            error.toString().contains('keychain') ||
            error.toString().contains('com.google.GIDSignIn') ||
            error.toString().contains('SIGN_IN_FAILED')) {
          
          // Check if this is specifically an iOS Simulator issue
          if (!kIsWeb && Platform.isIOS) {
            return {
              'success': false,
              'error': 'Google Sign-In is not fully supported in iOS Simulator. Please test on a physical iOS device for complete functionality.',
            };
          }
          
          return {
            'success': false,
            'error': 'Google Sign-In configuration error. Please check your Google Services configuration.',
          };
        }
        
        return {
          'success': false,
          'error': 'Google Sign-In failed: ${error.toString()}',
        };
      }
      
      if (googleUser == null) {
        SecurityConfig.logSecurityEvent('GOOGLE_SIGNIN_CANCELLED', {});
        return {
          'success': false,
          'error': 'Google sign-in was cancelled',
        };
      }

      SecurityConfig.logSecurityEvent('GOOGLE_SIGNIN_ACCOUNT_OBTAINED', {
        'email': googleUser.email,
      });

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        SecurityConfig.logSecurityEvent('GOOGLE_SIGNIN_NO_ID_TOKEN', {});
        return {
          'success': false,
          'error': 'Failed to get Google ID token',
        };
      }

      print('🔑 GOOGLE AUTH: Obtained Google ID token');

      // Send ID token to Django backend for verification
      final backendResult = await _authenticateWithBackend(googleAuth.idToken!);

      if (backendResult['success']) {
        SecurityConfig.logSecurityEvent('GOOGLE_SIGNIN_SUCCESS', {
          'email': googleUser.email,
          'user_id': backendResult['user_id'],
        });

        return backendResult;
      } else {
        SecurityConfig.logSecurityEvent('GOOGLE_SIGNIN_BACKEND_FAILED', {
          'email': googleUser.email,
          'error': backendResult['error'],
        });

        return backendResult;
      }
    } catch (e) {
      print('💥 GOOGLE AUTH: Error during Google sign-in: $e');
      SecurityConfig.logSecurityEvent('GOOGLE_SIGNIN_ERROR', {
        'error': e.toString(),
      });

      return {
        'success': false,
        'error': 'Google sign-in failed: ${e.toString()}',
      };
    }
  }

  /// Authenticate with Django backend using Google ID token
  Future<Map<String, dynamic>> _authenticateWithBackend(String googleIdToken) async {
    try {
      print('🔐 GOOGLE AUTH: Sending Google token to Django backend');

      // Try connecting to local Django server
      final response = await _httpClient.post(
        'auth/google/',
        body: {
          'google_token': googleIdToken,
        },
        requireAuth: false,
      ).timeout(
        const Duration(seconds: 10), // 10 second timeout for local server
        onTimeout: () {
          print('⏱️ GOOGLE AUTH: Local server request timed out after 10 seconds');
          throw Exception('Local server timeout - please ensure Django server is running on localhost:8000');
        },
      );

      print('🔐 GOOGLE AUTH: Backend response - Status: ${response.statusCode}, Success: ${response.isSuccess}');
      print('🔐 GOOGLE AUTH: Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('token') && data.containsKey('user') && data.containsKey('gym_owner')) {
          final user = data['user'] as Map<String, dynamic>;
          final gymOwner = data['gym_owner'] as Map<String, dynamic>;
          final token = data['token'] as String;
          final isNewUser = data['is_new_user'] as bool? ?? false;
          final needsProfileCompletion = data['needs_profile_completion'] as bool? ?? false;

          // Store authentication data using AuthService with persistent session flag
          final authService = AuthService();
          await authService.loginWithGoogleData(
            userData: {
              'id': gymOwner['id'],
              'firstName': user['first_name'],
              'lastName': user['last_name'],
              'email': user['email'],
              'phoneNumber': gymOwner['phone_number'] ?? '',
              'gymName': gymOwner['gym_name'],
              'gymAddress': gymOwner['gym_address'],
              'gymDescription': gymOwner['gym_description'],
              'createdAt': gymOwner['created_at'],
              'gymEstablishedDate': gymOwner['gym_established_date'],
            },
            token: token,
            isPersistentSession: true, // Mark as persistent Google session
          );

          return {
            'success': true,
            'user': user,
            'gym_owner': gymOwner,
            'token': token,
            'is_new_user': isNewUser,
            'needs_profile_completion': needsProfileCompletion,
            'message': data['message'] ?? 'Google authentication successful',
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? 'Invalid response from authentication server',
          };
        }
      } else {
        return {
          'success': false,
          'error': response.errorMessage ?? 'Google authentication failed',
        };
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('GOOGLE_BACKEND_AUTH_ERROR', {
        'error': e.toString(),
      });
      
      // Provide helpful error messages for local development
      if (e.toString().contains('timeout') || 
          e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'error': 'Cannot connect to local Django server. Please ensure:\n• Django server is running (python manage.py runserver)\n• Server is accessible at http://127.0.0.1:8000\n• Google OAuth endpoint is configured',
        };
      }
      
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection') ||
          e.toString().contains('Network')) {
        return {
          'success': false,
          'error': 'Connection failed. Please check:\n• Django server is running on port 8000\n• No firewall blocking the connection\n• Correct server URL configuration',
        };
      }
      
      return {
        'success': false,
        'error': 'Authentication service error: ${e.toString()}',
      };
    }
  }


  /// Sign out from Google
  Future<void> signOut() async {
    try {
      SecurityConfig.logSecurityEvent('GOOGLE_SIGNOUT_INITIATED', {});
      
      // Disconnect to revoke permissions completely
      await _googleSignIn.disconnect();
      
      SecurityConfig.logSecurityEvent('GOOGLE_SIGNOUT_COMPLETED', {});
      print('✅ GOOGLE AUTH: Signed out and disconnected from Google');
    } catch (e) {
      print('💥 GOOGLE AUTH: Error during Google sign-out: $e');
      SecurityConfig.logSecurityEvent('GOOGLE_SIGNOUT_ERROR', {
        'error': e.toString(),
      });
      
      // Fallback to regular signOut if disconnect fails
      try {
        await _googleSignIn.signOut();
        print('✅ GOOGLE AUTH: Fallback sign-out successful');
      } catch (fallbackError) {
        print('💥 GOOGLE AUTH: Fallback sign-out also failed: $fallbackError');
      }
    }
  }

  /// Check if user is currently signed in to Google
  Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      print('💥 GOOGLE AUTH: Error checking Google sign-in status: $e');
      return false;
    }
  }

  /// Get current Google user if signed in
  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return _googleSignIn.currentUser;
    } catch (e) {
      print('💥 GOOGLE AUTH: Error getting current Google user: $e');
      return null;
    }
  }

  /// Check if Google Sign-In is properly configured
  Future<bool> _isGoogleSignInConfigured() async {
    try {
      // Check if running on iOS Simulator (Google Sign-In has limitations)
      if (!kIsWeb && Platform.isIOS) {
        // iOS Simulator detection is complex, but we can check for known simulator identifiers
        // For now, we'll allow the configuration check to proceed
        print('🔑 GOOGLE AUTH: Running on iOS - checking configuration...');
      }
      
      // Try to initialize silently to check configuration
      await _googleSignIn.signInSilently();
      return true;
    } catch (e) {
      print('🔑 GOOGLE AUTH: Configuration check failed: $e');
      
      // Check for iOS Simulator specific errors
      if (e.toString().contains('simulator') || 
          e.toString().contains('Simulator') ||
          e.toString().contains('SIGN_IN_FAILED_SIMULATOR')) {
        print('⚠️ GOOGLE AUTH: Detected iOS Simulator - Google Sign-In may have limitations');
        return false;
      }
      
      if (e.toString().contains('GoogleService-Info.plist') || 
          e.toString().contains('google-services.json') ||
          e.toString().contains('SIGN_IN_REQUIRED') ||
          e.toString().contains('configuration')) {
        return false;
      }
      // Other errors might be acceptable (like no previous sign-in)
      return true;
    }
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.dispose();
  }
}