import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/gym_owner.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';
import '../services/web_api_service.dart';
import '../services/gym_data_service.dart';
import '../services/database_reset_service.dart';
import '../services/data_refresh_service.dart';
import '../services/google_auth_service.dart';
import '../security/jwt_manager.dart';
import 'member_provider.dart';
import 'attendance_provider.dart';
import 'trainer_provider.dart';
import 'equipment_provider.dart';
import 'payment_provider.dart';
import 'subscription_provider.dart';
import 'user_profile_provider.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  GymOwner? _currentUser;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _errorMessage;

  GymOwner? get currentUser => _currentUser;
  GymOwner? get user => _currentUser; // Alias for compatibility
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    // Register callback with AuthService for immediate state updates
    AuthService.setAuthStateChangeCallback(() {
      if (kDebugMode) print('🔄 AUTH_PROVIDER: Auth state change callback triggered');
      _checkLoginStatus();
    });
    
    // For web, delay initial check to ensure proper initialization
    if (kIsWeb) {
      if (kDebugMode) print('🌐 AUTH_PROVIDER: Web platform - scheduling delayed auth check');
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkLoginStatus();
      });
    } else {
      _checkLoginStatus();
    }
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Ensure JWT web storage is fully initialized for web platform
      if (kIsWeb) {
        if (kDebugMode) print('🔧 AUTH_PROVIDER: Ensuring web storage is initialized...');
        await JWTManager.initializeWebStorage();
        // Add a longer delay to ensure localStorage is fully ready and stable
        await Future.delayed(const Duration(milliseconds: 300));
        if (kDebugMode) print('✅ AUTH_PROVIDER: Web storage initialization completed');
      }
      
      _isLoggedIn = await _authService.isLoggedIn();
      if (kDebugMode) print('🔍 AUTH_PROVIDER: Login status check result: $_isLoggedIn');
      
      if (_isLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
        if (kDebugMode) print('✅ AUTH_PROVIDER: Current user retrieved: ${_currentUser?.email}');
        
        // Test token availability after login status check with retry for web platform
        String? token;
        if (kIsWeb) {
          // For web, add multiple attempts to account for localStorage timing issues
          for (int attempt = 0; attempt < 5; attempt++) {
            token = await JWTManager.getAccessToken();
            if (token != null) break;
            
            if (kDebugMode) print('🔄 AUTH_PROVIDER: Token check attempt ${attempt + 1}/5 - waiting for web storage...');
            await Future.delayed(Duration(milliseconds: 100 * (attempt + 1))); // Progressive delay
          }
        } else {
          token = await JWTManager.getAccessToken();
        }
        
        if (token == null) {
          if (kDebugMode) print('❌ AUTH_PROVIDER: CRITICAL - User marked as logged in but no tokens available after retries!');
          if (kDebugMode) print('🔄 AUTH_PROVIDER: Forcing logout due to missing tokens');
          
          // Force logout since login state is inconsistent with token state
          _isLoggedIn = false;
          _currentUser = null;
          await _authService.logout();
          
          if (kDebugMode) print('✅ AUTH_PROVIDER: Forced logout completed - user must re-authenticate');
        } else {
          if (kDebugMode) print('✅ AUTH_PROVIDER: Token available after login status check');
          
          // Initialize gym-specific data isolation with mock data enabled
          GymDataService().initialize(_currentUser, enableMockData: true);
        }
      } else {
        if (kDebugMode) print('ℹ️ AUTH_PROVIDER: User not logged in');
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Public method to manually trigger login status check
  Future<void> checkLoginStatus() async {
    await _checkLoginStatus();
  }


  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> result;
      
      // Use WebApiService for web platform, AuthService for mobile
      if (kIsWeb) {
        print('🌐 AUTH_PROVIDER: Using WebApiService for web login');
        result = await WebApiService.login(
          email: email,
          password: password,
        );
        
        if (kDebugMode) {
          print('🌐 AUTH_PROVIDER: WebApiService raw response: $result');
          print('🌐 AUTH_PROVIDER: Response success: ${result['success']}');
          print('🌐 AUTH_PROVIDER: Response data keys: ${result['data']?.keys?.toList()}');
        }
        
        // Convert WebApiService response to AuthService format
        if (result['success']) {
          final responseData = result['data'] as Map<String, dynamic>;
          
          if (kDebugMode) {
            print('🌐 AUTH_PROVIDER: Response data: $responseData');
            print('🌐 AUTH_PROVIDER: Contains gym_owner: ${responseData.containsKey('gym_owner')}');
            print('🌐 AUTH_PROVIDER: Contains token: ${responseData.containsKey('token')}');
            print('🌐 AUTH_PROVIDER: Token value: ${responseData['token']}');
          }
          
          result = {
            'success': true,
            'userData': responseData['gym_owner'],
            'token': responseData['token'],
            'message': responseData['message'],
          };
        }
      } else {
        print('📱 AUTH_PROVIDER: Using AuthService for mobile login');
        result = await _authService.login(email, password);
      }
      
      if (result['success']) {
        // Convert userData map to GymOwner object
        final userData = result['userData'] ?? result['user'];
        if (userData is Map<String, dynamic>) {
          _currentUser = GymOwner(
            id: userData['id'],
            firstName: userData['firstName'] ?? '',
            lastName: userData['lastName'] ?? '',
            email: userData['email'] ?? '',
            phoneNumber: userData['phoneNumber'] ?? '',
            gymName: userData['gymName'] ?? '',
            gymAddress: userData['gymAddress'] ?? '',
            gymDescription: userData['gymDescription'] ?? '',
            createdAt: DateTime.tryParse(userData['createdAt'] ?? '') ?? DateTime.now(),
            updatedAt: DateTime.now(),
            gymEstablishedDate: DateTime.tryParse(userData['gymEstablishedDate'] ?? '') ?? DateTime.now().subtract(const Duration(days: 365)),
          );
        } else {
          _currentUser = userData as GymOwner?;
        }
        _isLoggedIn = true;
        
        // Store token if provided
        if (result['token'] != null) {
          if (kDebugMode) {
            print('🔐 AUTH_PROVIDER: Storing authentication token...');
            print('🔐 AUTH_PROVIDER: Token length: ${result['token'].toString().length}');
            print('🔐 AUTH_PROVIDER: Token preview: ${result['token'].toString().substring(0, 10)}...');
          }
          
          await JWTManager.storeTokens(
            accessToken: result['token'],
            refreshToken: result['token'],
            userId: _currentUser?.id.toString() ?? '',
            userRole: 'gym_owner',
            sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
            persistent: true,
          );
          if (kDebugMode) print('✅ AUTH_PROVIDER: Token storage completed');
          
          // Add delay for web localStorage to fully commit
          if (kIsWeb) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (kDebugMode) print('🌐 AUTH_PROVIDER: Added web storage commit delay');
          }
          
          // Immediately test token retrieval after storage
          final testToken = await JWTManager.getAccessToken();
          if (testToken == null) {
            if (kDebugMode) {
              print('❌ AUTH_PROVIDER: Token retrieval test failed immediately after storage');
              // Try multiple times for web platform
              if (kIsWeb) {
                for (int i = 0; i < 3; i++) {
                  await Future.delayed(const Duration(milliseconds: 100));
                  final retryToken = await JWTManager.getAccessToken();
                  if (retryToken != null) {
                    if (kDebugMode) print('✅ AUTH_PROVIDER: Token retrieval succeeded on retry ${i + 1}');
                    break;
                  }
                  if (kDebugMode) print('❌ AUTH_PROVIDER: Token retrieval retry ${i + 1} failed');
                }
              }
            }
          } else {
            if (kDebugMode) {
              print('✅ AUTH_PROVIDER: Token retrieval test successful');
              print('✅ AUTH_PROVIDER: Retrieved token length: ${testToken.length}');
              print('✅ AUTH_PROVIDER: Retrieved token preview: ${testToken.substring(0, 10)}...');
            }
          }
        } else {
          if (kDebugMode) print('⚠️ AUTH_PROVIDER: No token provided in login result');
        }
        
        // Initialize gym-specific data isolation with mock data enabled
        GymDataService().initialize(_currentUser, enableMockData: true);
        
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'user': _currentUser};
      } else {
        _errorMessage = result['error'] ?? result['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'error': _errorMessage};
      }
    } catch (e) {
      print('❌ AUTH_PROVIDER: Login error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? gymName,
    String? gymAddress,
    String? gymDescription,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      Map<String, dynamic> result;
      
      // Use WebApiService for web platform, AuthService for mobile
      if (kIsWeb) {
        print('🌐 AUTH_PROVIDER: Using WebApiService for web registration');
        result = await WebApiService.register(
          firstName: firstName,
          lastName: lastName,
          email: email,
          password: password,
          gymName: gymName ?? 'My Gym',
          gymAddress: gymAddress ?? 'Default Address',
          gymDescription: gymDescription ?? 'Default Description',
          phoneNumber: phoneNumber,
        );
        
        // Convert WebApiService response to AuthService format
        if (result['success']) {
          final responseData = result['data'] as Map<String, dynamic>;
          result = {
            'success': true,
            'user': responseData['gym_owner'],
            'token': responseData['token'],
            'message': responseData['message'],
          };
        }
      } else {
        print('📱 AUTH_PROVIDER: Using AuthService for mobile registration');
        result = await _authService.register(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: phoneNumber,
          gymName: gymName,
          gymAddress: gymAddress,
          gymDescription: gymDescription,
        );
      }
      
      if (result['success']) {
        _currentUser = result['user'];
        _isLoggedIn = true;
        
        // Store token if provided
        if (result['token'] != null) {
          await JWTManager.storeTokens(
            accessToken: result['token'],
            refreshToken: result['token'],
            userId: _currentUser?.id.toString() ?? '',
            userRole: 'gym_owner',
            sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
            persistent: true,
          );
        }
        
        // Initialize gym-specific data isolation for new account with mock data enabled
        GymDataService().initialize(_currentUser, enableMockData: true);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['error'] ?? result['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      print('❌ AUTH_PROVIDER: Registration error: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();
    
    // Clear gym-specific data isolation and reset all local data
    await DatabaseResetService.resetAllData();
    
    _currentUser = null;
    _isLoggedIn = false;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Enhanced logout that clears all provider data
  Future<void> logoutWithDataClear(BuildContext context) async {
    try {
      print('🚪 AUTH: Starting enhanced logout with complete data clear...');
      
      // Prevent double logout calls
      if (_isLoading) {
        print('⚠️ AUTH: Logout already in progress, skipping...');
        return;
      }
      
      _isLoading = true;
      notifyListeners();

      // Check if this is a Google session and sign out from Google (only once)
      if (await JWTManager.isSessionPersistent()) {
        try {
          print('🔍 AUTH: Detected persistent Google session, signing out...');
          final googleAuthService = GoogleAuthService();
          await googleAuthService.signOut();
          print('✅ AUTH: Signed out from Google successfully');
        } catch (e) {
          print('⚠️ AUTH: Error signing out from Google: $e');
        }
      }

      // Get all providers and clear their data immediately
      try {
        final memberProvider = Provider.of<MemberProvider>(context, listen: false);
        final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
        final trainerProvider = Provider.of<TrainerProvider>(context, listen: false);
        final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
        final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
        final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
        final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
        
        // Step 1: Clear all provider data immediately
        print('🧹 AUTH: Clearing all provider data...');
        memberProvider.clearAllData();
        attendanceProvider.clearAllData();
        trainerProvider.clearAllData();
        equipmentProvider.clearAllData();
        paymentProvider.clearAllData();
        subscriptionProvider.clearAllData();
        userProfileProvider.clearAllData();
        print('✅ AUTH: Provider data cleared successfully');
      } catch (e) {
        print('⚠️ AUTH: Error clearing provider data: $e');
        // Continue with logout even if provider clearing fails
      }
      
      // Step 2: Clear gym data service
      try {
        GymDataService().nuclearClear();
        print('✅ AUTH: Gym data service cleared');
      } catch (e) {
        print('⚠️ AUTH: Error clearing gym data service: $e');
      }
      
      // Step 3: Logout from auth service
      try {
        await _authService.logout();
        print('✅ AUTH: Auth service logout completed');
      } catch (e) {
        print('⚠️ AUTH: Error during auth service logout: $e');
      }
      
      // Step 4: Nuclear reset of all stored data
      try {
        await DatabaseResetService.nuclearReset();
        print('✅ AUTH: Database reset completed');
      } catch (e) {
        print('⚠️ AUTH: Error during database reset: $e');
      }
      
      // Step 5: Reset auth provider state - THIS IS CRITICAL FOR NAVIGATION
      _currentUser = null;
      _isLoggedIn = false;
      _errorMessage = null;
      _isLoading = false;
      
      // Force immediate notification to trigger navigation
      notifyListeners();
      
      // Add a small delay and notify again to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();
      
      print('✅ AUTH: Enhanced logout completed - all data cleared');
      print('🔄 AUTH: Current state - isLoggedIn: $_isLoggedIn, currentUser: $_currentUser');
      
      // Navigate to login screen manually if auto-navigation fails
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        print('🏠 AUTH: Manual navigation to login screen completed');
      }
      
    } catch (e) {
      print('💥 AUTH: Error during enhanced logout: $e');
      _errorMessage = 'Logout error: $e';
      _isLoading = false;
      _currentUser = null;
      _isLoggedIn = false;
      notifyListeners();
      
      // Even if logout fails, try to navigate to login screen
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        print('🏠 AUTH: Emergency navigation to login screen after error');
      }
    }
  }

  /// Clear all cached authentication data (for debugging)
  Future<void> clearAuthData() async {
    print('🗑️ AuthProvider: Clearing all auth data...');
    _isLoggedIn = false;
    _currentUser = null;
    _errorMessage = null;
    
    await _authService.clearAuthData();
    
    notifyListeners();
    print('✅ AuthProvider: Auth data cleared');
  }
  
  /// Start fresh login with clean slate (no mock data)
  Future<bool> loginClean(String email, String password) async {
    try {
      // First do regular login
      final loginResult = await login(email, password);
      
      if (loginResult['success'] == true && _currentUser != null) {
        // Reinitialize with mock data disabled for clean start
        GymDataService().initialize(_currentUser, enableMockData: false);
        print('🆕 AUTH: Clean login completed - user will start with empty data');
        return true;
      }
      
      return false;
    } catch (e) {
      print('💥 AUTH: Error during clean login: $e');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Refresh authentication status (public method to trigger _checkLoginStatus)
  Future<void> refreshAuthStatus() async {
    print('🔄 AuthProvider.refreshAuthStatus: Starting refresh...');
    await _checkLoginStatus();
    print('✅ AuthProvider.refreshAuthStatus: Completed. isLoggedIn = $_isLoggedIn, user = ${_currentUser?.email}');
  }
  
  /// Set loading state (used by UI components)
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Force complete data reset and refresh for new account
  Future<void> resetAndRefreshData() async {
    try {
      print('🔄 AUTH: Starting complete data reset and refresh...');
      
      // Reset all local data
      await DatabaseResetService.resetAllData();
      
      // Re-initialize gym data service if user is logged in (with fresh start - no mock data)
      if (_isLoggedIn && _currentUser != null) {
        GymDataService().initialize(_currentUser, enableMockData: false);
        print('✅ AUTH: Re-initialized gym data service for user: ${_currentUser!.displayName} (fresh start)');
      }
      
      notifyListeners();
      print('🎉 AUTH: Data reset and refresh completed successfully!');
      
    } catch (e) {
      print('💥 AUTH: Error during data reset and refresh: $e');
      _errorMessage = 'Failed to reset data: $e';
      notifyListeners();
    }
  }
  
  /// Force fresh state for testing/development
  Future<void> forceCleanState() async {
    try {
      print('🔥 AUTH: Initiating nuclear reset...');
      
      // Use nuclear reset to completely destroy all data
      await DatabaseResetService.nuclearReset();
      
      // Reset all auth state
      _currentUser = null;
      _isLoggedIn = false;
      _errorMessage = null;
      _isLoading = false;
      
      // Clear gym data service
      GymDataService().nuclearClear();
      
      notifyListeners();
      
      print('☢️ AUTH: Nuclear reset completed - fresh slate achieved');
      
    } catch (e) {
      print('💥 AUTH: Error in nuclear reset: $e');
      _errorMessage = 'Failed to perform nuclear reset: $e';
      notifyListeners();
    }
  }
  
  /// Trigger immediate refresh of all providers when gym context changes
  Future<void> triggerGymContextRefresh(BuildContext context) async {
    try {
      print('🔄 AUTH: Triggering gym context refresh for providers...');
      
      // Get all providers without listening
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final trainerProvider = Provider.of<TrainerProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      
      // Force immediate refresh for gym change
      await DataRefreshService.forceImmediateRefreshForGymChange(
        memberProvider: memberProvider,
        attendanceProvider: attendanceProvider,
        trainerProvider: trainerProvider,
        equipmentProvider: equipmentProvider,
        paymentProvider: paymentProvider,
        subscriptionProvider: subscriptionProvider,
        userProfileProvider: userProfileProvider,
      );
      
      print('✅ AUTH: Gym context refresh completed successfully');
      
    } catch (e) {
      print('💥 AUTH: Error triggering gym context refresh: $e');
      // Don't throw here to prevent blocking login/registration
    }
  }
}