import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/gym_owner.dart';
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
      _checkLoginStatus();
    });
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _isLoggedIn = await _authService.isLoggedIn();
      
      if (_isLoggedIn) {
        _currentUser = await _authService.getCurrentUser();
        
        // Initialize gym-specific data isolation with mock data enabled
        GymDataService().initialize(_currentUser, enableMockData: true);
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
        
        // Convert WebApiService response to AuthService format
        if (result['success']) {
          final responseData = result['data'] as Map<String, dynamic>;
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
          await JWTManager.storeTokens(
            accessToken: result['token'],
            refreshToken: result['token'],
            userId: _currentUser?.id.toString() ?? '',
            userRole: 'gym_owner',
            sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
            persistent: true,
          );
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
      
      _isLoading = true;
      notifyListeners();

      // Check if this is a Google session and sign out from Google
      if (await JWTManager.isSessionPersistent()) {
        try {
          final googleAuthService = GoogleAuthService();
          await googleAuthService.signOut();
          print('✅ AUTH: Signed out from Google successfully');
        } catch (e) {
          print('⚠️ AUTH: Error signing out from Google: $e');
        }
      }

      // Get all providers and clear their data immediately
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final trainerProvider = Provider.of<TrainerProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      
      // Step 1: Clear all provider data immediately
      print('🧹 Clearing all provider data...');
      memberProvider.clearAllData();
      attendanceProvider.clearAllData();
      trainerProvider.clearAllData();
      equipmentProvider.clearAllData();
      paymentProvider.clearAllData();
      subscriptionProvider.clearAllData();
      userProfileProvider.clearAllData();
      
      // Step 2: Clear gym data service
      GymDataService().nuclearClear();
      
      // Step 3: Logout from auth service
      await _authService.logout();
      
      // Step 4: Nuclear reset of all stored data
      await DatabaseResetService.nuclearReset();
      
      // Step 5: Reset auth provider state
      _currentUser = null;
      _isLoggedIn = false;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      
      print('✅ AUTH: Enhanced logout completed - all data cleared');
      
    } catch (e) {
      print('💥 AUTH: Error during enhanced logout: $e');
      _errorMessage = 'Logout error: $e';
      _isLoading = false;
      notifyListeners();
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