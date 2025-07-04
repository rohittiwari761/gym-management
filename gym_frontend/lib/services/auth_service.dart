import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/gym_owner.dart';
import '../security/security_config.dart';
import '../security/input_validator.dart';
import '../security/jwt_manager.dart';
import '../security/secure_http_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _userKey = 'secure_user_data';
  static const String _loginAttemptsKey = 'login_attempts';
  static const String _lastAttemptKey = 'last_attempt_time';
  
  final SecureHttpClient _httpClient = SecureHttpClient();
  final Map<String, int> _loginAttempts = {};
  final Map<String, DateTime> _lastAttemptTimes = {};

  /// Initialize authentication service
  void initialize() {
    _httpClient.initialize();
    SecurityConfig.logSecurityEvent('AUTH_SERVICE_INITIALIZED', {});
  }

  /// Secure login with comprehensive validation and security measures
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      SecurityConfig.logSecurityEvent('LOGIN_ATTEMPT', {
        'email': InputValidator.sanitizeInput(email),
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Validate input
      final emailValidation = InputValidator.validateEmail(email);
      if (!emailValidation.isValid) {
        SecurityConfig.logSecurityEvent('LOGIN_VALIDATION_FAILED', {
          'reason': 'invalid_email',
          'email': InputValidator.sanitizeInput(email),
        });
        return {'success': false, 'error': emailValidation.message};
      }

      final passwordValidation = InputValidator.validatePassword(password);
      if (!passwordValidation.isValid) {
        SecurityConfig.logSecurityEvent('LOGIN_VALIDATION_FAILED', {
          'reason': 'invalid_password',
          'email': InputValidator.sanitizeInput(email),
        });
        return {'success': false, 'error': passwordValidation.message};
      }

      // Check rate limiting
      if (!_checkLoginRateLimit(email)) {
        SecurityConfig.logSecurityEvent('LOGIN_RATE_LIMITED', {
          'email': InputValidator.sanitizeInput(email),
        });
        return {
          'success': false,
          'error': 'Too many login attempts. Please wait ${SecurityConfig.loginCooldownSeconds ~/ 60} minutes before trying again.'
        };
      }

      // Hash password for secure comparison
      final sanitizedEmail = InputValidator.sanitizeInput(email.toLowerCase());
      
      // Call Django backend authentication
      final authResult = await _authenticateWithBackend(sanitizedEmail, password);
      
      if (!authResult['success']) {
        print('❌ AUTH: Django backend authentication failed, trying fallback auth');
        // Fallback to local authentication for backwards compatibility
        final fallbackResult = await _authenticateUser(sanitizedEmail, password);
        
        if (!fallbackResult['success']) {
          _incrementLoginAttempts(email);
          SecurityConfig.logSecurityEvent('LOGIN_FAILED', {
            'email': sanitizedEmail,
            'reason': authResult['error'],
            'attempts': _getLoginAttempts(email),
          });
          return authResult; // Return Django backend error as primary
        }
        
        print('✅ AUTH: Fallback authentication successful');
        // Use fallback authentication result
        final userData = fallbackResult['userData'] as Map<String, dynamic>;
        final userRole = fallbackResult['role'] as String;
        
        // Generate secure session for fallback auth
        final sessionId = JWTManager.generateSessionId();
        final accessToken = SecurityConfig.generateSecureToken(64);
        final refreshToken = SecurityConfig.generateSecureToken(64);
        
        // Store tokens securely
        await JWTManager.storeTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          userId: userData['id'].toString(),
          userRole: userRole,
          sessionId: sessionId,
        );

        // Create user object for secure storage
        final user = GymOwner(
          id: userData['id'],
          firstName: userData['firstName'],
          lastName: userData['lastName'],
          email: userData['email'],
          phoneNumber: userData['phoneNumber'] ?? '',
          gymName: userData['gymName'],
          gymAddress: userData['gymAddress'],
          gymDescription: userData['gymDescription'],
          createdAt: DateTime.parse(userData['createdAt'] ?? DateTime.now().toIso8601String()),
          updatedAt: DateTime.now(),
          gymEstablishedDate: DateTime.parse(userData['gymEstablishedDate'] ?? DateTime.now().subtract(const Duration(days: 365)).toIso8601String()),
        );

        // Store user data securely
        await _storeUserData(user);

        // Reset login attempts on successful fallback login
        _resetLoginAttempts(email);

        SecurityConfig.logSecurityEvent('LOGIN_SUCCESS_FALLBACK', {
          'email': sanitizedEmail,
          'role': userRole,
          'sessionId': sessionId,
        });

        return {
          'success': true,
          'user': userData,
          'role': userRole,
          'token': accessToken,
          'sessionId': sessionId,
        };
      }

      // Reset login attempts on successful login
      _resetLoginAttempts(email);

      final userData = authResult['userData'] as Map<String, dynamic>;
      final userRole = authResult['role'] as String;
      final backendToken = authResult['token'] as String?;
      
      // Generate secure session
      final sessionId = JWTManager.generateSessionId();
      final accessToken = backendToken ?? SecurityConfig.generateSecureToken(64);
      final refreshToken = SecurityConfig.generateSecureToken(64);
      
      // Store tokens securely
      await JWTManager.storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userData['id'].toString(),
        userRole: userRole,
        sessionId: sessionId,
      );

      // Create user object
      final user = GymOwner(
        id: userData['id'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        email: userData['email'],
        phoneNumber: userData['phoneNumber'] ?? '',
        gymName: userData['gymName'],
        gymAddress: userData['gymAddress'],
        gymDescription: userData['gymDescription'],
        createdAt: DateTime.parse(userData['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.now(),
        gymEstablishedDate: DateTime.parse(userData['gymEstablishedDate'] ?? DateTime.now().subtract(const Duration(days: 365)).toIso8601String()),
      );

      // Store user data securely
      await _storeUserData(user);

      SecurityConfig.logSecurityEvent('LOGIN_SUCCESS', {
        'userId': userData['id'].toString(),
        'role': userRole,
        'sessionId': sessionId,
      });

      return {
        'success': true,
        'user': user,
        'token': accessToken,
        'sessionId': sessionId,
      };
    } catch (e) {
      SecurityConfig.logSecurityEvent('LOGIN_ERROR', {
        'error': e.toString(),
        'email': InputValidator.sanitizeInput(email),
      });
      return {'success': false, 'error': 'Authentication service error. Please try again.'};
    }
  }

  /// Authenticate with Django backend
  Future<Map<String, dynamic>> _authenticateWithBackend(String email, String password) async {
    try {
      print('🔐 AUTH: Attempting Django backend authentication for $email');
      final response = await _httpClient.post('auth/login/', body: {
        'email': email,
        'password': password,
      }, requireAuth: false);

      print('🔐 AUTH: Backend response - Status: ${response.statusCode}, Success: ${response.isSuccess}');
      print('🔐 AUTH: Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Check if this is a successful Django login response
        if (data['success'] == true) {
          final gymOwner = data['gym_owner'] as Map<String, dynamic>;
          final user = data['user'] as Map<String, dynamic>;
          final token = data['token'] as String;

          print('✅ AUTH: Django authentication successful for ${user['email']}');
          
          return {
            'success': true,
            'userData': {
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
            'role': 'admin',
            'token': token,
          };
        } else {
          print('❌ AUTH: Django backend returned unsuccessful response');
          return {
            'success': false,
            'error': data['error'] ?? 'Authentication failed',
          };
        }
      } else {
        print('❌ AUTH: Django backend request failed - ${response.errorMessage}');
        return {
          'success': false,
          'error': response.errorMessage ?? 'Authentication failed',
        };
      }
    } catch (e) {
      print('💥 AUTH: Backend authentication error: $e');
      SecurityConfig.logSecurityEvent('BACKEND_AUTH_ERROR', {
        'error': e.toString(),
        'email': InputValidator.sanitizeInput(email),
      });
      return {'success': false, 'error': 'Authentication service error'};
    }
  }

  /// Register with Django backend
  Future<Map<String, dynamic>> _registerWithBackend({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? gymName,
    String? gymAddress,
    String? gymDescription,
  }) async {
    try {
      print('📝 REGISTER: Attempting Django backend registration for $email');
      final response = await _httpClient.post('auth/register/', body: {
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber ?? '',
        'gym_name': gymName ?? '$firstName\'s Fitness Center',
        'gym_address': gymAddress ?? 'Address Not Set',
        'gym_description': gymDescription ?? 'Professional fitness center',
      }, requireAuth: false);

      print('📝 REGISTER: Backend response - Status: ${response.statusCode}, Success: ${response.isSuccess}');
      print('📝 REGISTER: Response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Check if this is a successful Django registration response
        if (data['success'] == true) {
          final gymOwner = data['gym_owner'] as Map<String, dynamic>;
          final user = data['user'] as Map<String, dynamic>;
          final token = data['token'] as String;

          print('✅ REGISTER: Django registration successful for ${user['email']}');

          return {
            'success': true,
            'userData': {
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
            'role': 'admin',
            'token': token,
          };
        } else {
          print('❌ REGISTER: Django backend returned unsuccessful response');
          return {
            'success': false,
            'error': data['error'] ?? 'Registration failed',
          };
        }
      } else {
        print('❌ REGISTER: Django backend request failed - ${response.errorMessage}');
        return {
          'success': false,
          'error': response.errorMessage ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('💥 REGISTER: Backend registration error: $e');
      SecurityConfig.logSecurityEvent('BACKEND_REGISTRATION_ERROR', {
        'error': e.toString(),
        'email': InputValidator.sanitizeInput(email),
      });
      return {'success': false, 'error': 'Registration service error'};
    }
  }

  /// Secure user authentication (fallback to local auth)
  Future<Map<String, dynamic>> _authenticateUser(String email, String password) async {
    try {
      // First check stored users (registered users)
      final storedUser = await _getStoredUser(email);
      if (storedUser != null) {
        final userData = storedUser;
        final storedHash = userData['passwordHash'] as String;
        final salt = userData['salt'] as String;

        // Verify password with secure hashing
        if (!SecurityConfig.verifyPassword(password, salt, storedHash)) {
          await Future.delayed(const Duration(milliseconds: 500)); // Prevent timing attacks
          return {'success': false, 'error': 'Invalid credentials. Please check your email and password.'};
        }

        return {
          'success': true,
          'userData': userData,
          'role': userData['role'],
        };
      }
      
      // Fallback to hardcoded admin users for initial setup
      final validUsers = {
        'admin@gym.com': {
          'id': 1,
          'firstName': 'Admin',
          'lastName': 'User',
          'email': 'admin@gym.com',
          'passwordHash': SecurityConfig.hashPassword('admin123', 'secure_salt_admin'),
          'salt': 'secure_salt_admin',
          'role': 'super_admin',
          'gymName': 'Elite Fitness Center',
          'gymAddress': 'Mumbai, Maharashtra',
          'gymDescription': 'Premium fitness center',
          'createdAt': DateTime.now().subtract(const Duration(days: 365)).toIso8601String(),
          'gymEstablishedDate': DateTime.now().subtract(const Duration(days: 1095)).toIso8601String(),
        },
        'owner@fitnesscenter.com': {
          'id': 2,
          'firstName': 'Gym',
          'lastName': 'Owner',
          'email': 'owner@fitnesscenter.com',
          'passwordHash': SecurityConfig.hashPassword('owner123', 'secure_salt_owner'),
          'salt': 'secure_salt_owner',
          'role': 'admin',
          'gymName': 'Fitness Pro Gym',
          'gymAddress': 'Delhi, India',
          'gymDescription': 'Professional fitness center',
          'createdAt': DateTime.now().subtract(const Duration(days: 300)).toIso8601String(),
          'gymEstablishedDate': DateTime.now().subtract(const Duration(days: 800)).toIso8601String(),
        },
        'manager@gym.in': {
          'id': 3,
          'firstName': 'Manager',
          'lastName': 'Singh',
          'email': 'manager@gym.in',
          'passwordHash': SecurityConfig.hashPassword('manager123', 'secure_salt_manager'),
          'salt': 'secure_salt_manager',
          'role': 'trainer',
          'gymName': 'PowerHouse Gym',
          'gymAddress': 'Bangalore, Karnataka',
          'gymDescription': 'Modern fitness facility',
          'createdAt': DateTime.now().subtract(const Duration(days: 180)).toIso8601String(),
          'gymEstablishedDate': DateTime.now().subtract(const Duration(days: 600)).toIso8601String(),
        },
      };

      if (!validUsers.containsKey(email)) {
        await Future.delayed(const Duration(milliseconds: 500)); // Prevent timing attacks
        return {'success': false, 'error': 'Invalid credentials. Please check your email and password.'};
      }

      final userData = validUsers[email]!;
      final storedHash = userData['passwordHash'] as String;
      final salt = userData['salt'] as String;

      // Verify password with secure hashing
      if (!SecurityConfig.verifyPassword(password, salt, storedHash)) {
        await Future.delayed(const Duration(milliseconds: 500)); // Prevent timing attacks
        return {'success': false, 'error': 'Invalid credentials. Please check your email and password.'};
      }

      return {
        'success': true,
        'userData': userData,
        'role': userData['role'],
      };
    } catch (e) {
      SecurityConfig.logSecurityEvent('AUTHENTICATION_ERROR', {
        'error': e.toString(),
        'email': InputValidator.sanitizeInput(email),
      });
      return {'success': false, 'error': 'Authentication service error. Please try again.'};
    }
  }

  /// Secure registration with comprehensive validation
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? gymName,
    String? gymAddress,
    String? gymDescription,
  }) async {
    try {
      SecurityConfig.logSecurityEvent('REGISTRATION_ATTEMPT', {
        'email': InputValidator.sanitizeInput(email),
      });

      // Validate all inputs
      final emailValidation = InputValidator.validateEmail(email);
      final passwordValidation = InputValidator.validatePassword(password);
      final firstNameValidation = InputValidator.validateName(firstName, fieldName: 'First name');
      final lastNameValidation = InputValidator.validateName(lastName, fieldName: 'Last name');

      if (!emailValidation.isValid) {
        return {'success': false, 'error': emailValidation.message};
      }
      if (!passwordValidation.isValid) {
        return {'success': false, 'error': passwordValidation.message};
      }
      if (!firstNameValidation.isValid) {
        return {'success': false, 'error': firstNameValidation.message};
      }
      if (!lastNameValidation.isValid) {
        return {'success': false, 'error': lastNameValidation.message};
      }

      // Validate optional fields
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        final phoneValidation = InputValidator.validatePhoneNumber(phoneNumber);
        if (!phoneValidation.isValid) {
          return {'success': false, 'error': phoneValidation.message};
        }
      }

      if (gymName != null && gymName.isNotEmpty) {
        final gymNameValidation = InputValidator.validateTextInput(
          gymName,
          maxLength: 100,
          fieldName: 'Gym name',
        );
        if (!gymNameValidation.isValid) {
          return {'success': false, 'error': gymNameValidation.message};
        }
      }

      if (gymAddress != null && gymAddress.isNotEmpty) {
        final gymAddressValidation = InputValidator.validateTextInput(
          gymAddress,
          maxLength: 200,
          fieldName: 'Gym address',
        );
        if (!gymAddressValidation.isValid) {
          return {'success': false, 'error': gymAddressValidation.message};
        }
      }

      if (gymDescription != null && gymDescription.isNotEmpty) {
        final gymDescriptionValidation = InputValidator.validateTextInput(
          gymDescription,
          maxLength: 500,
          fieldName: 'Gym description',
        );
        if (!gymDescriptionValidation.isValid) {
          return {'success': false, 'error': gymDescriptionValidation.message};
        }
      }

      // Check if user already exists
      final sanitizedEmail = InputValidator.sanitizeInput(email.toLowerCase());
      if (await _userExists(sanitizedEmail)) {
        SecurityConfig.logSecurityEvent('REGISTRATION_DENIED', {
          'email': sanitizedEmail,
          'reason': 'user_already_exists',
        });
        return {
          'success': false,
          'error': 'An account with this email already exists. Please use a different email or try logging in.'
        };
      }

      // Create new user with Django backend
      final registrationResult = await _registerWithBackend(
        email: sanitizedEmail,
        password: password,
        firstName: InputValidator.sanitizeInput(firstName),
        lastName: InputValidator.sanitizeInput(lastName),
        phoneNumber: phoneNumber != null ? InputValidator.sanitizeInput(phoneNumber) : null,
        gymName: gymName != null ? InputValidator.sanitizeInput(gymName) : null,
        gymAddress: gymAddress != null ? InputValidator.sanitizeInput(gymAddress) : null,
        gymDescription: gymDescription != null ? InputValidator.sanitizeInput(gymDescription) : null,
      );

      if (!registrationResult['success']) {
        return registrationResult;
      }

      final userData = registrationResult['userData'] as Map<String, dynamic>;
      final userRole = registrationResult['role'] as String;
      final backendToken = registrationResult['token'] as String?;
      
      // Generate secure session
      final sessionId = JWTManager.generateSessionId();
      final accessToken = backendToken ?? SecurityConfig.generateSecureToken(64);
      final refreshToken = SecurityConfig.generateSecureToken(64);
      
      // Store tokens securely
      await JWTManager.storeTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: userData['id'].toString(),
        userRole: userRole,
        sessionId: sessionId,
      );

      // Create user object
      final user = GymOwner(
        id: userData['id'],
        firstName: userData['firstName'],
        lastName: userData['lastName'],
        email: userData['email'],
        phoneNumber: userData['phoneNumber'] ?? '',
        gymName: userData['gymName'] ?? 'My Gym',
        gymAddress: userData['gymAddress'] ?? 'Address Not Set',
        gymDescription: userData['gymDescription'] ?? 'Fitness Center',
        createdAt: DateTime.parse(userData['createdAt']),
        updatedAt: DateTime.now(),
        gymEstablishedDate: DateTime.parse(userData['gymEstablishedDate']),
      );

      // Store user data securely
      await _storeUserData(user);

      SecurityConfig.logSecurityEvent('REGISTRATION_SUCCESS', {
        'userId': userData['id'].toString(),
        'role': userRole,
        'sessionId': sessionId,
      });

      return {
        'success': true,
        'user': user,
        'token': accessToken,
        'sessionId': sessionId,
        'message': 'Registration successful! Welcome to the gym management system.',
      };
    } catch (e) {
      SecurityConfig.logSecurityEvent('REGISTRATION_ERROR', {
        'error': e.toString(),
      });
      return {'success': false, 'error': 'Registration service error. Please try again.'};
    }
  }


  /// Secure logout with session cleanup
  Future<void> logout() async {
    try {
      final userInfo = await JWTManager.getUserInfo();
      
      SecurityConfig.logSecurityEvent('LOGOUT_INITIATED', {
        'userId': userInfo?.userId,
        'sessionId': userInfo?.sessionId,
      });

      // Call Django backend logout to invalidate token on server
      try {
        await _httpClient.post('auth/logout/', requireAuth: true);
        print('✅ AUTH: Successfully logged out from Django backend');
      } catch (e) {
        print('⚠️ AUTH: Backend logout failed (may not be critical): $e');
        // Continue with local logout even if backend fails
      }

      // Clear all authentication data
      await JWTManager.clearTokens();
      await _clearUserData();

      SecurityConfig.logSecurityEvent('LOGOUT_COMPLETED', {});
    } catch (e) {
      SecurityConfig.logSecurityEvent('LOGOUT_ERROR', {
        'error': e.toString(),
      });
    }
  }

  /// Clear all authentication data (for debugging)
  Future<void> clearAuthData() async {
    print('🗑️ AuthService: Clearing all auth data...');
    
    try {
      // Clear stored tokens and user data
      await JWTManager.clearTokens();
      await _clearUserData();
      
      SecurityConfig.logSecurityEvent('AUTH_DATA_CLEARED', {});
      print('✅ AuthService: Auth data cleared successfully');
    } catch (e) {
      print('💥 AuthService: Error clearing auth data: $e');
      SecurityConfig.logSecurityEvent('AUTH_CLEAR_ERROR', {
        'error': e.toString(),
      });
    }
  }

  /// Get access token with validation
  Future<String?> getToken() async {
    try {
      return await JWTManager.getAccessToken();
    } catch (e) {
      SecurityConfig.logSecurityEvent('TOKEN_RETRIEVAL_ERROR', {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Get current user with security validation
  Future<GymOwner?> getCurrentUser() async {
    try {
      // Ensure token is valid
      if (!await JWTManager.ensureValidToken()) {
        return null;
      }

      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      final userData = await storage.read(key: _userKey);
      if (userData != null) {
        final decryptedData = jsonDecode(userData);
        return GymOwner.fromJson(decryptedData);
      }
      return null;
    } catch (e) {
      SecurityConfig.logSecurityEvent('USER_RETRIEVAL_ERROR', {
        'error': e.toString(),
      });
      return null;
    }
  }

  /// Check if user is logged in with token validation
  Future<bool> isLoggedIn() async {
    try {
      return await JWTManager.ensureValidToken();
    } catch (e) {
      return false;
    }
  }

  /// Get secure auth headers
  Future<Map<String, String>> getAuthHeaders() async {
    try {
      final token = await getToken();
      final headers = {
        'Content-Type': 'application/json',
        ...SecurityConfig.securityHeaders,
      };
      
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }
      
      return headers;
    } catch (e) {
      SecurityConfig.logSecurityEvent('AUTH_HEADERS_ERROR', {
        'error': e.toString(),
      });
      return {'Content-Type': 'application/json'};
    }
  }

  /// Refresh authentication token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      SecurityConfig.logSecurityEvent('TOKEN_REFRESH_REQUESTED', {});
      
      final refreshToken = await JWTManager.getRefreshToken();
      if (refreshToken == null) {
        return {'success': false, 'error': 'No refresh token found'};
      }

      // In a real implementation, this would call the backend API
      final success = await JWTManager.refreshAccessToken();
      
      if (success) {
        SecurityConfig.logSecurityEvent('TOKEN_REFRESH_SUCCESS', {});
        final newToken = await JWTManager.getAccessToken();
        return {'success': true, 'token': newToken};
      } else {
        SecurityConfig.logSecurityEvent('TOKEN_REFRESH_FAILED', {});
        await logout();
        return {'success': false, 'error': 'Token refresh failed. Please log in again.'};
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('TOKEN_REFRESH_ERROR', {
        'error': e.toString(),
      });
      return {'success': false, 'error': 'Token refresh error. Please log in again.'};
    }
  }

  /// Check if user has required role
  Future<bool> hasRole(UserRole requiredRole) async {
    return await JWTManager.hasRole(requiredRole);
  }

  /// Check if user has specific permission
  Future<bool> hasPermission(String permission) async {
    return await JWTManager.hasPermission(permission);
  }

  /// Store user data securely
  Future<void> _storeUserData(GymOwner user) async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      await storage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } catch (e) {
      SecurityConfig.logSecurityEvent('USER_STORAGE_ERROR', {
        'error': e.toString(),
      });
    }
  }

  /// Clear user data
  Future<void> _clearUserData() async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      await storage.delete(key: _userKey);
    } catch (e) {
      SecurityConfig.logSecurityEvent('USER_DATA_CLEAR_ERROR', {
        'error': e.toString(),
      });
    }
  }

  /// Check login rate limiting
  bool _checkLoginRateLimit(String email) {
    final now = DateTime.now();
    final attempts = _getLoginAttempts(email);
    final lastAttempt = _lastAttemptTimes[email];

    if (attempts >= SecurityConfig.maxLoginAttempts) {
      if (lastAttempt != null &&
          now.difference(lastAttempt).inSeconds < SecurityConfig.loginCooldownSeconds) {
        return false;
      } else {
        // Reset attempts after cooldown period
        _resetLoginAttempts(email);
      }
    }

    return true;
  }

  /// Get login attempts for email
  int _getLoginAttempts(String email) {
    return _loginAttempts[email] ?? 0;
  }

  /// Increment login attempts
  void _incrementLoginAttempts(String email) {
    _loginAttempts[email] = _getLoginAttempts(email) + 1;
    _lastAttemptTimes[email] = DateTime.now();
  }

  /// Reset login attempts
  void _resetLoginAttempts(String email) {
    _loginAttempts.remove(email);
    _lastAttemptTimes.remove(email);
  }

  /// Get stored user by email
  Future<Map<String, dynamic>?> _getStoredUser(String email) async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      final userData = await storage.read(key: 'stored_user_$email');
      if (userData != null) {
        return jsonDecode(userData);
      }
      return null;
    } catch (e) {
      SecurityConfig.logSecurityEvent('STORED_USER_RETRIEVAL_ERROR', {
        'error': e.toString(),
        'email': InputValidator.sanitizeInput(email),
      });
      return null;
    }
  }

  /// Store user data permanently for login
  Future<void> _storeUser(String email, Map<String, dynamic> userData) async {
    try {
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
          keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
          storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        ),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

      await storage.write(key: 'stored_user_$email', value: jsonEncode(userData));
    } catch (e) {
      SecurityConfig.logSecurityEvent('STORED_USER_STORAGE_ERROR', {
        'error': e.toString(),
        'email': InputValidator.sanitizeInput(email),
      });
    }
  }

  /// Check if user exists
  Future<bool> _userExists(String email) async {
    try {
      // Check stored users
      final storedUser = await _getStoredUser(email);
      if (storedUser != null) return true;
      
      // Check hardcoded users
      final validUsers = ['admin@gym.com', 'owner@fitnesscenter.com', 'manager@gym.in'];
      return validUsers.contains(email);
    } catch (e) {
      return false;
    }
  }

  /// Create new user and store securely
  Future<Map<String, dynamic>> _createNewUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? gymName,
    String? gymAddress,
    String? gymDescription,
  }) async {
    try {
      // Generate secure salt and hash password
      final salt = SecurityConfig.generateSalt();
      final hashedPassword = SecurityConfig.hashPassword(password, salt);
      
      // Generate new user ID (unique timestamp-based ID)
      final newUserId = DateTime.now().millisecondsSinceEpoch % 100000;
      
      // Assign role based on registration (new users get 'admin' role by default)
      const defaultRole = 'admin';
      
      final userData = {
        'id': newUserId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'passwordHash': hashedPassword,
        'salt': salt,
        'role': defaultRole,
        'phoneNumber': phoneNumber ?? '',
        'gymName': gymName ?? '$firstName\'s Fitness Center',
        'gymAddress': gymAddress ?? 'Address Not Set',
        'gymDescription': gymDescription ?? 'Professional fitness center',
        'createdAt': DateTime.now().toIso8601String(),
        'gymEstablishedDate': DateTime.now().toIso8601String(),
      };

      // Store user permanently for future logins
      await _storeUser(email, userData);

      SecurityConfig.logSecurityEvent('NEW_USER_CREATED', {
        'userId': newUserId.toString(),
        'email': email,
        'role': defaultRole,
      });

      return {
        'success': true,
        'userData': userData,
        'role': defaultRole,
      };
    } catch (e) {
      SecurityConfig.logSecurityEvent('USER_CREATION_ERROR', {
        'error': e.toString(),
      });
      return {'success': false, 'error': 'Failed to create user account'};
    }
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.dispose();
  }
}