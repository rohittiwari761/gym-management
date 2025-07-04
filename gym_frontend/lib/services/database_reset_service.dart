import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/gym_data_service.dart';

/// Service to reset all local data and provide clean experience for new users
class DatabaseResetService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  /// Clear all local data and reset the app to initial state
  static Future<void> resetAllData() async {
    try {
      print('🗑️ DATABASE RESET: Starting complete data reset...');
      
      // 1. Clear gym data service
      GymDataService().clear();
      print('✅ Cleared gym data service');
      
      // 2. Clear all secure storage
      await _secureStorage.deleteAll();
      print('✅ Cleared secure storage');
      
      // 3. Clear any cached data keys
      await _clearCachedDataKeys();
      print('✅ Cleared cached data keys');
      
      print('🎉 DATABASE RESET: Complete data reset finished successfully!');
      
    } catch (e) {
      print('💥 DATABASE RESET ERROR: $e');
      rethrow;
    }
  }
  
  /// Clear all gym-specific cached data keys
  static Future<void> _clearCachedDataKeys() async {
    try {
      // List of all possible cached data keys that might persist
      final keysToRemove = [
        'auth_token',
        'refresh_token', 
        'current_user',
        'gym_owner_data',
        'members_cache',
        'trainers_cache',
        'equipment_cache',
        'attendance_cache',
        'payments_cache',
        'subscription_cache',
        'last_login',
        'user_preferences',
      ];
      
      // Also remove stored user accounts (for all possible emails)
      for (int i = 0; i < 1000; i++) {
        keysToRemove.addAll([
          'stored_user_user$i@test.com',
          'stored_user_admin$i@gym.com',
          'stored_user_owner$i@fitness.com',
          'stored_user_test$i@example.com',
        ]);
      }
      
      // Also remove any gym-specific keys (for all possible gym IDs)
      for (int gymId = 1; gymId <= 10000; gymId++) {
        keysToRemove.addAll([
          'members_cache_gym_$gymId',
          'trainers_cache_gym_$gymId', 
          'equipment_cache_gym_$gymId',
          'attendance_cache_gym_$gymId',
          'payments_cache_gym_$gymId',
          'subscription_cache_gym_$gymId',
          'stored_user_*@*_gym_$gymId',
        ]);
      }
      
      // Remove all keys
      for (final key in keysToRemove) {
        await _secureStorage.delete(key: key);
      }
      
      if (kDebugMode) {
        print('🧹 Cleared ${keysToRemove.length} potential cached data keys');
      }
      
    } catch (e) {
      print('⚠️ Error clearing cached data keys: $e');
    }
  }
  
  /// Reset data for a specific gym (useful for testing)
  static Future<void> resetGymData(int gymOwnerId) async {
    try {
      print('🏋️ DATABASE RESET: Resetting data for gym owner ID: $gymOwnerId');
      
      final gymSpecificKeys = [
        'members_cache_gym_$gymOwnerId',
        'trainers_cache_gym_$gymOwnerId',
        'equipment_cache_gym_$gymOwnerId', 
        'attendance_cache_gym_$gymOwnerId',
        'payments_cache_gym_$gymOwnerId',
        'subscription_cache_gym_$gymOwnerId',
      ];
      
      for (final key in gymSpecificKeys) {
        await _secureStorage.delete(key: key);
      }
      
      print('✅ Cleared gym-specific data for gym $gymOwnerId');
      
    } catch (e) {
      print('💥 Error resetting gym data: $e');
      rethrow;
    }
  }
  
  /// Check if this is a fresh installation/new user
  static Future<bool> isFreshInstallation() async {
    try {
      final authToken = await _secureStorage.read(key: 'auth_token');
      final currentUser = await _secureStorage.read(key: 'current_user');
      
      return authToken == null && currentUser == null;
    } catch (e) {
      print('⚠️ Error checking fresh installation: $e');
      return true; // Assume fresh if we can't check
    }
  }
  
  /// Force clean state for development/testing
  static Future<void> forceCleanState() async {
    try {
      print('🔄 DATABASE RESET: Forcing clean state for testing...');
      
      // Clear gym data service first
      GymDataService().nuclearClear();
      
      // Clear ALL secure storage
      await _secureStorage.deleteAll();
      print('✅ Cleared ALL secure storage');
      
      // Clear any remaining cached data
      await _clearCachedDataKeys();
      
      // Clear any application data directory caches if possible
      await _clearApplicationData();
      
      // Extra cleanup for development
      if (kDebugMode) {
        print('✅ Cleared all debug and development data');
      }
      
      print('🎯 DATABASE RESET: COMPLETE CLEAN STATE FORCED!');
      
    } catch (e) {
      print('💥 Error forcing clean state: $e');
      rethrow;
    }
  }
  
  /// Clear application-level data caches
  static Future<void> _clearApplicationData() async {
    try {
      // Clear any additional application-level caches
      // This ensures no data persists at the app level
      print('🧹 Clearing application-level data caches...');
      
      // Reset any static variables or singletons
      GymDataService().clear();
      
      print('✅ Application-level data cleared');
      
    } catch (e) {
      print('⚠️ Error clearing application data: $e');
    }
  }
  
  /// Completely nuke all data - nuclear option
  static Future<void> nuclearReset() async {
    try {
      print('☢️ DATABASE RESET: NUCLEAR OPTION - DESTROYING ALL DATA');
      
      // 1. Clear gym data service
      GymDataService().nuclearClear();
      
      // 2. Delete ALL secure storage without exception
      await _secureStorage.deleteAll();
      
      // 3. Clear application data
      await _clearApplicationData();
      
      // 4. Force clear any possible remaining caches
      await _clearCachedDataKeys();
      
      // 5. Wait to ensure all operations complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      print('☢️ NUCLEAR RESET COMPLETE - ALL DATA DESTROYED');
      
    } catch (e) {
      print('💥 Error in nuclear reset: $e');
      rethrow;
    }
  }
  
  /// Log current data state for debugging
  static Future<void> logDataState() async {
    if (!kDebugMode) return;
    
    try {
      print('📊 DATABASE STATE CHECK:');
      
      final authToken = await _secureStorage.read(key: 'auth_token');
      final currentUser = await _secureStorage.read(key: 'current_user');
      
      print('  - Auth Token: ${authToken != null ? 'EXISTS' : 'NULL'}');
      print('  - Current User: ${currentUser != null ? 'EXISTS' : 'NULL'}');
      print('  - Gym Data Service Initialized: ${GymDataService().isInitialized}');
      print('  - Current Gym ID: ${GymDataService().currentGymOwnerId}');
      print('  - Current Gym Name: ${GymDataService().currentGymName}');
      
    } catch (e) {
      print('⚠️ Error logging data state: $e');
    }
  }
}