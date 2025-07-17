import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../security/security_config.dart';
import '../security/secure_http_client.dart';
import 'auth_service.dart';

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  
  late final GoogleSignIn _googleSignIn;
  bool _isSigningIn = false;  // Guard against duplicate requests

  GoogleAuthService._internal() {
    // Configure GoogleSignIn based on platform
    if (kIsWeb) {
      // Web client ID - configured for Web Application type
      // Updated configuration for better web compatibility and ID token support
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile', 'openid'],
        clientId: '818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g.apps.googleusercontent.com',
        // Additional web-specific configurations for better compatibility
        signInOption: SignInOption.standard,
      );
    } else {
      // Mobile apps use the iOS client ID
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
        forceCodeForRefreshToken: true,
      );
    }
  }

  final SecureHttpClient _httpClient = SecureHttpClient();

  /// Initialize Google Sign-In
  void initialize() {
    try {
      _httpClient.initialize();
      
      // Pre-initialize Google Sign-In to catch any configuration issues early
      _googleSignIn.signInSilently().catchError((error) {
        return null;
      });
      
      SecurityConfig.logSecurityEvent('GOOGLE_AUTH_SERVICE_INITIALIZED', {});
    } catch (e) {
      SecurityConfig.logSecurityEvent('GOOGLE_AUTH_INIT_ERROR', {
        'error': e.toString(),
      });
    }
  }

  /// Check and restore previous Google Sign-In session
  Future<Map<String, dynamic>?> restorePreviousSession() async {
    try {
      
      // Check if user was previously signed in
      final isSignedIn = await _googleSignIn.isSignedIn();
      if (!isSignedIn) {
        return null;
      }

      // Try to restore the session
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) {
        return null;
      }

      
      // Get fresh authentication token
      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        return null;
      }

      // Authenticate with backend using restored token
      final backendResult = await _authenticateWithBackend(googleAuth.idToken!);
      
      if (backendResult['success']) {
        SecurityConfig.logSecurityEvent('GOOGLE_SESSION_RESTORED', {
          'email': googleUser.email,
        });
        return backendResult;
      } else {
        // Clear the invalid session
        await _googleSignIn.signOut();
        return null;
      }
    } catch (e) {
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
          'error': kIsWeb 
              ? 'Google Sign-In is not properly configured for web. Please check your web client ID configuration.'
              : 'Google Sign-In is not properly configured. Please check GoogleService-Info.plist for iOS or google-services.json for Android.',
        };
      }

      // Start Google Sign-In process with enhanced error handling
      GoogleSignInAccount? googleUser;
      
      try {
        print('🔐 GOOGLE_AUTH: Starting sign-in process...');
        if (kIsWeb) {
          print('🌐 GOOGLE_AUTH: Web platform detected, using web client ID');
          print('🌐 GOOGLE_AUTH: Client ID: 818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g.apps.googleusercontent.com');
        } else {
          print('📱 GOOGLE_AUTH: Mobile platform detected, using mobile client ID');
          print('📱 GOOGLE_AUTH: Server client ID: 818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com');
        }
        
        print('🔄 GOOGLE_AUTH: Calling _googleSignIn.signIn()...');
        googleUser = await _googleSignIn.signIn();
        print('✅ GOOGLE_AUTH: Sign-in process completed successfully');
        if (googleUser != null) {
          print('👤 GOOGLE_AUTH: User signed in: ${googleUser.email}');
        } else {
          print('❌ GOOGLE_AUTH: Sign-in returned null - user cancelled or failed');
        }
      } catch (error) {
        print('❌ GOOGLE_AUTH: Sign-in error: $error');
        
        // Handle web-specific errors
        if (kIsWeb) {
          print('🌐 GOOGLE_AUTH: Handling web-specific error');
          if (error.toString().contains('popup') || 
              error.toString().contains('blocked') ||
              error.toString().contains('network_error') ||
              error.toString().contains('ERR_BLOCKED_BY_CLIENT')) {
            return {
              'success': false,
              'error': 'Google Sign-In blocked by ad blocker or browser extension. Please disable ad blockers for this site and try again.',
            };
          }
          
          if (error.toString().contains('idpiframe') || 
              error.toString().contains('gapi')) {
            return {
              'success': false,
              'error': 'Google Sign-In failed to load. Please check your internet connection and try again.',
            };
          }
          
          if (error.toString().contains('access_denied') || 
              error.toString().contains('unauthorized_client')) {
            return {
              'success': false,
              'error': 'Google Sign-In access denied. Please check that this domain is authorized in Google Console.',
            };
          }
          
          return {
            'success': false,
            'error': 'Google Sign-In failed on web. Error: ${error.toString()}. Please try refreshing the page.',
          };
        }
        
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
      print('🔑 GOOGLE_AUTH: Getting authentication details from googleUser...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      print('🔍 GOOGLE_AUTH: Authentication object received');
      print('🔍 GOOGLE_AUTH: idToken: ${googleAuth.idToken != null ? "PRESENT (${googleAuth.idToken!.length} chars)" : "NULL"}');
      print('🔍 GOOGLE_AUTH: accessToken: ${googleAuth.accessToken != null ? "PRESENT (${googleAuth.accessToken!.length} chars)" : "NULL"}');

      if (googleAuth.idToken == null) {
        print('❌ GOOGLE_AUTH: ID token is null - trying fallback with access token');
        SecurityConfig.logSecurityEvent('GOOGLE_SIGNIN_NO_ID_TOKEN', {});
        
        // Fallback: try to get user info from access token
        if (googleAuth.accessToken != null) {
          print('🔄 GOOGLE_AUTH: Using access token fallback method');
          try {
            // Use access token to get user info from Google API directly
            final userInfoResponse = await http.get(
              Uri.parse('https://www.googleapis.com/oauth2/v2/userinfo'),
              headers: {
                'Authorization': 'Bearer ${googleAuth.accessToken}',
                'Accept': 'application/json',
              },
            );
            
            if (userInfoResponse.statusCode == 200) {
              final userInfo = jsonDecode(userInfoResponse.body);
              print('✅ GOOGLE_AUTH: Got user info from access token');
              
              // Create a simple auth token for the backend
              final fallbackResult = await _authenticateWithEmailFallback(
                email: userInfo['email'],
                name: userInfo['name'],
                googleId: userInfo['id'],
              );
              
              return fallbackResult;
            }
          } catch (e) {
            print('❌ GOOGLE_AUTH: Access token fallback failed: $e');
          }
        }
        
        return {
          'success': false,
          'error': 'Failed to get Google ID token and access token fallback failed',
        };
      }
      
      print('✅ GOOGLE_AUTH: ID token successfully obtained');


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
      print('🔐 GOOGLE_AUTH: Sending token to backend...');
      print('🔑 GOOGLE_AUTH: Token length: ${googleIdToken.length}');
      print('🔑 GOOGLE_AUTH: Token starts with: ${googleIdToken.substring(0, 50)}...');
      print('🌐 GOOGLE_AUTH: Platform: ${kIsWeb ? "Web" : "Mobile"}');
      print('🌐 GOOGLE_AUTH: Expected backend support: Both web and mobile client IDs');
      
      // Try connecting to Django server
      final response = await _httpClient.post(
        'auth/google/',
        body: {
          'google_token': googleIdToken,
          'platform': kIsWeb ? 'web' : 'mobile', // Add platform info for backend debugging
          'client_id': kIsWeb 
              ? '818835282138-qjqc6v2bf8n89ghrphh9l388erj5vt5g.apps.googleusercontent.com'
              : '818835282138-8h3qf505eco222l28feg0o1t3tvu0v8g.apps.googleusercontent.com',
        },
        requireAuth: false,
      ).timeout(
        const Duration(seconds: 10), // 10 second timeout
        onTimeout: () {
          throw Exception('Server timeout - please ensure Django server is accessible');
        },
      );


      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        if (data.containsKey('token') && data.containsKey('user') && data.containsKey('gym_owner')) {
          final user = data['user'] as Map<String, dynamic>;
          final gymOwner = data['gym_owner'] as Map<String, dynamic>;
          final token = data['token'] as String;
          final isNewUser = data['is_new_user'] as bool? ?? false;
          final needsProfileCompletion = data['needs_profile_completion'] as bool? ?? false;

          print('🔵 GOOGLE AUTH: Storing authentication data in AuthService...');
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
          print('🔵 GOOGLE AUTH: Authentication data stored successfully');

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
        // Check for specific error cases
        if (response.statusCode == 404) {
          print('⚠️ GOOGLE_AUTH: Google authentication endpoint not available on server');
          return {
            'success': false,
            'error': 'Google Sign-In is temporarily unavailable. Please use email registration instead.',
          };
        } else if (response.statusCode == 401) {
          print('🔑 GOOGLE_AUTH: Authentication failed (401) - checking error details...');
          final errorData = response.data;
          if (errorData is Map<String, dynamic>) {
            final errorMsg = errorData['error'] ?? 'Authentication failed';
            print('❌ GOOGLE_AUTH: Server error: $errorMsg');
            
            if (errorMsg.toString().contains('Invalid Google token')) {
              return {
                'success': false,
                'error': 'Google Sign-In failed. Please try again or use email registration.',
              };
            }
          }
          return {
            'success': false,
            'error': 'Google authentication failed. Please try email registration instead.',
          };
        }
        
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
    } catch (e) {
      SecurityConfig.logSecurityEvent('GOOGLE_SIGNOUT_ERROR', {
        'error': e.toString(),
      });
      
      // Fallback to regular signOut if disconnect fails
      try {
        await _googleSignIn.signOut();
      } catch (fallbackError) {
      }
    }
  }

  /// Check if user is currently signed in to Google
  Future<bool> isSignedIn() async {
    try {
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      return false;
    }
  }

  /// Get current Google user if signed in
  Future<GoogleSignInAccount?> getCurrentUser() async {
    try {
      return _googleSignIn.currentUser;
    } catch (e) {
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
      }
      
      // Try to initialize silently to check configuration
      await _googleSignIn.signInSilently();
      return true;
    } catch (e) {
      
      // Check for iOS Simulator specific errors
      if (e.toString().contains('simulator') || 
          e.toString().contains('Simulator') ||
          e.toString().contains('SIGN_IN_FAILED_SIMULATOR')) {
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

  /// Authenticate with backend using email fallback (when ID token is not available)
  Future<Map<String, dynamic>> _authenticateWithEmailFallback({
    required String email,
    required String name,
    required String googleId,
  }) async {
    try {
      print('🔄 GOOGLE_AUTH: Attempting email fallback authentication');
      
      // Try to register/login with email-based authentication
      final response = await _httpClient.post(
        'auth/google-fallback/',
        body: {
          'email': email,
          'name': name,
          'google_id': googleId,
        },
        requireAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        print('✅ GOOGLE_AUTH: Fallback authentication successful');
        
        // Store the authentication data
        final authService = AuthService();
        await authService.loginWithGoogleData(
          userData: {
            'id': data['gym_owner']['id'],
            'firstName': data['user']['first_name'],
            'lastName': data['user']['last_name'],
            'email': data['user']['email'],
            'phoneNumber': data['gym_owner']['phone_number'] ?? '',
            'gymName': data['gym_owner']['gym_name'],
            'gymAddress': data['gym_owner']['gym_address'],
            'gymDescription': data['gym_owner']['gym_description'],
            'createdAt': data['gym_owner']['created_at'],
            'gymEstablishedDate': data['gym_owner']['gym_established_date'],
          },
          token: data['token'],
          isPersistentSession: true,
        );
        
        return {
          'success': true,
          'user': data['user'],
          'gym_owner': data['gym_owner'],
          'token': data['token'],
          'message': 'Google authentication successful (fallback method)',
        };
      } else {
        print('❌ GOOGLE_AUTH: Fallback authentication failed');
        return {
          'success': false,
          'error': 'Fallback authentication failed: ${response.errorMessage}',
        };
      }
    } catch (e) {
      print('❌ GOOGLE_AUTH: Fallback authentication exception: $e');
      return {
        'success': false,
        'error': 'Fallback authentication failed: ${e.toString()}',
      };
    }
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.dispose();
  }
}