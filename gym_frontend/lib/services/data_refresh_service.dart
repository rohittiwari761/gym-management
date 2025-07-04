import 'package:flutter/foundation.dart';
import '../providers/member_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/trainer_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/user_profile_provider.dart';
import '../services/gym_data_service.dart';
import '../services/database_reset_service.dart';

/// Service to coordinate data refresh across all providers for new gym accounts
class DataRefreshService {
  
  /// Force immediate data clear and refresh when gym context changes
  static Future<void> forceImmediateRefreshForGymChange({
    MemberProvider? memberProvider,
    AttendanceProvider? attendanceProvider,
    TrainerProvider? trainerProvider,
    EquipmentProvider? equipmentProvider,
    PaymentProvider? paymentProvider,
    SubscriptionProvider? subscriptionProvider,
    UserProfileProvider? userProfileProvider,
  }) async {
    try {
      print('🚨 DATA REFRESH: FORCE IMMEDIATE REFRESH FOR GYM CHANGE');
      
      // Step 1: Immediately clear all existing data
      print('🧹 Step 1: Clearing all existing data...');
      memberProvider?.clearAllData();
      attendanceProvider?.clearAllData();
      trainerProvider?.clearAllData();
      equipmentProvider?.clearAllData();
      paymentProvider?.clearAllData();
      subscriptionProvider?.clearAllData();
      userProfileProvider?.clearAllData();
      
      // Step 2: Force complete refresh with new gym context
      print('🔄 Step 2: Generating fresh data for new gym...');
      await refreshAllDataForNewGym(
        memberProvider: memberProvider,
        attendanceProvider: attendanceProvider,
        trainerProvider: trainerProvider,
        equipmentProvider: equipmentProvider,
        paymentProvider: paymentProvider,
        subscriptionProvider: subscriptionProvider,
        userProfileProvider: userProfileProvider,
      );
      
      print('✅ FORCE IMMEDIATE REFRESH COMPLETED!');
      
    } catch (e) {
      print('💥 ERROR in force immediate refresh: $e');
      rethrow;
    }
  }
  
  /// Clear all data from all providers and force refresh for new gym context
  static Future<void> refreshAllDataForNewGym({
    MemberProvider? memberProvider,
    AttendanceProvider? attendanceProvider,
    TrainerProvider? trainerProvider,
    EquipmentProvider? equipmentProvider,
    PaymentProvider? paymentProvider,
    SubscriptionProvider? subscriptionProvider,
    UserProfileProvider? userProfileProvider,
  }) async {
    try {
      print('🔄 DATA REFRESH: Starting complete data refresh for new gym...');
      
      // Step 1: Clear all provider data
      await _clearAllProviderData(
        memberProvider: memberProvider,
        attendanceProvider: attendanceProvider,
        trainerProvider: trainerProvider,
        equipmentProvider: equipmentProvider,
        paymentProvider: paymentProvider,
        subscriptionProvider: subscriptionProvider,
        userProfileProvider: userProfileProvider,
      );
      
      // Step 2: Ensure gym data service is properly initialized
      if (!GymDataService().isInitialized) {
        print('⚠️ DATA REFRESH: Gym data service not initialized, skipping refresh');
        return;
      }
      
      print('🏋️ DATA REFRESH: Refreshing for gym: ${GymDataService().currentGymName} (ID: ${GymDataService().currentGymOwnerId})');
      
      // Step 3: Force refresh all provider data
      await _refreshAllProviderData(
        memberProvider: memberProvider,
        attendanceProvider: attendanceProvider,
        trainerProvider: trainerProvider,
        equipmentProvider: equipmentProvider,
        paymentProvider: paymentProvider,
        subscriptionProvider: subscriptionProvider,
        userProfileProvider: userProfileProvider,
      );
      
      print('🎉 DATA REFRESH: Complete data refresh finished successfully!');
      
    } catch (e) {
      print('💥 DATA REFRESH ERROR: $e');
      rethrow;
    }
  }
  
  /// Clear all data from all providers
  static Future<void> _clearAllProviderData({
    MemberProvider? memberProvider,
    AttendanceProvider? attendanceProvider,
    TrainerProvider? trainerProvider,
    EquipmentProvider? equipmentProvider,
    PaymentProvider? paymentProvider,
    SubscriptionProvider? subscriptionProvider,
    UserProfileProvider? userProfileProvider,
  }) async {
    try {
      print('🧹 DATA REFRESH: Clearing all provider data...');
      
      // Clear in parallel for efficiency
      await Future.wait([
        if (memberProvider != null) Future(() => memberProvider.clearAllData()),
        if (attendanceProvider != null) Future(() => attendanceProvider.clearAllData()),
        if (trainerProvider != null) Future(() => trainerProvider.clearAllData()),
        if (equipmentProvider != null) Future(() => equipmentProvider.clearAllData()),
        if (paymentProvider != null) Future(() => paymentProvider.clearAllData()),
        if (subscriptionProvider != null) Future(() => subscriptionProvider.clearAllData()),
        if (userProfileProvider != null) Future(() => userProfileProvider.clearAllData()),
      ]);
      
      print('✅ DATA REFRESH: All provider data cleared');
      
    } catch (e) {
      print('💥 DATA REFRESH: Error clearing provider data: $e');
      rethrow;
    }
  }
  
  /// Refresh all provider data
  static Future<void> _refreshAllProviderData({
    MemberProvider? memberProvider,
    AttendanceProvider? attendanceProvider,
    TrainerProvider? trainerProvider,
    EquipmentProvider? equipmentProvider,
    PaymentProvider? paymentProvider,
    SubscriptionProvider? subscriptionProvider,
    UserProfileProvider? userProfileProvider,
  }) async {
    try {
      print('🔄 DATA REFRESH: Refreshing all provider data...');
      
      // Refresh members first (needed for attendance name resolution)
      if (memberProvider != null) {
        print('👥 DATA REFRESH: Refreshing members...');
        await memberProvider.forceRefresh();
      }
      
      // Then refresh other providers in parallel
      await Future.wait([
        if (trainerProvider != null) trainerProvider.forceRefresh(),
        if (equipmentProvider != null) equipmentProvider.forceRefresh(),
        if (paymentProvider != null) paymentProvider.forceRefresh(),
        if (subscriptionProvider != null) subscriptionProvider.forceRefresh(),
        if (userProfileProvider != null) userProfileProvider.forceRefresh(),
      ]);
      
      // Refresh attendance last (after members are loaded)
      if (attendanceProvider != null && memberProvider != null) {
        print('📋 DATA REFRESH: Refreshing attendance...');
        // Update attendance with member cache first
        attendanceProvider.updateMembersCache(memberProvider.members);
        await attendanceProvider.forceRefresh();
      }
      
      print('✅ DATA REFRESH: All provider data refreshed successfully');
      
    } catch (e) {
      print('💥 DATA REFRESH: Error refreshing provider data: $e');
      rethrow;
    }
  }
  
  /// Force complete reset and refresh (for new account creation)
  static Future<void> forceCompleteReset({
    MemberProvider? memberProvider,
    AttendanceProvider? attendanceProvider,
    TrainerProvider? trainerProvider,
    EquipmentProvider? equipmentProvider,
    PaymentProvider? paymentProvider,
    SubscriptionProvider? subscriptionProvider,
    UserProfileProvider? userProfileProvider,
  }) async {
    try {
      print('🔥 DATA REFRESH: Force complete reset and refresh...');
      
      // Step 1: Reset all local storage and cache
      await DatabaseResetService.resetAllData();
      
      // Step 2: Clear all provider data
      await _clearAllProviderData(
        memberProvider: memberProvider,
        attendanceProvider: attendanceProvider,
        trainerProvider: trainerProvider,
        equipmentProvider: equipmentProvider,
        paymentProvider: paymentProvider,
        subscriptionProvider: subscriptionProvider,
        userProfileProvider: userProfileProvider,
      );
      
      // Step 3: Refresh all data with new gym context
      await refreshAllDataForNewGym(
        memberProvider: memberProvider,
        attendanceProvider: attendanceProvider,
        trainerProvider: trainerProvider,
        equipmentProvider: equipmentProvider,
        paymentProvider: paymentProvider,
        subscriptionProvider: subscriptionProvider,
        userProfileProvider: userProfileProvider,
      );
      
      print('🎯 DATA REFRESH: Force complete reset finished!');
      
    } catch (e) {
      print('💥 DATA REFRESH: Error in force complete reset: $e');
      rethrow;
    }
  }
  
  /// Log current data state across all providers for debugging
  static void logCurrentDataState({
    MemberProvider? memberProvider,
    AttendanceProvider? attendanceProvider,
    TrainerProvider? trainerProvider,
    EquipmentProvider? equipmentProvider,
    PaymentProvider? paymentProvider,
  }) {
    if (!kDebugMode) return;
    
    print('📊 DATA STATE SUMMARY:');
    print('  🏋️ Gym: ${GymDataService().currentGymName} (ID: ${GymDataService().currentGymOwnerId})');
    print('  👥 Members: ${memberProvider?.members.length ?? 'N/A'}');
    print('  📋 Attendance: ${attendanceProvider?.attendances.length ?? 'N/A'}');
    print('  👨‍💼 Trainers: ${trainerProvider?.trainers.length ?? 'N/A'}');
    print('  🔧 Equipment: ${equipmentProvider?.equipment.length ?? 'N/A'}');
    print('  💰 Payments: ${paymentProvider?.payments.length ?? 'N/A'}');
  }
}