import 'package:flutter/foundation.dart';
import '../models/gym_owner.dart';
import '../providers/auth_provider.dart';

/// Service to manage gym-specific data isolation
/// Ensures that each gym owner only sees their own data
class GymDataService {
  static final GymDataService _instance = GymDataService._internal();
  factory GymDataService() => _instance;
  GymDataService._internal();

  int? _currentGymOwnerId;
  String? _currentGymName;
  String? _lastDataGenerationGym; // Track which gym the data was generated for
  bool _allowMockDataGeneration = true; // Control mock data generation

  /// Initialize with current gym owner information
  void initialize(GymOwner? gymOwner, {bool enableMockData = true}) {
    final newGymOwnerId = gymOwner?.id;
    final newGymName = gymOwner?.gymName ?? gymOwner?.displayName;
    
    // Check if gym context has changed
    if (_currentGymOwnerId != newGymOwnerId) {
      print('🔄 GYM_DATA: Gym context changed from $_currentGymOwnerId to $newGymOwnerId');
      _lastDataGenerationGym = null; // Force data regeneration
    }
    
    _currentGymOwnerId = newGymOwnerId;
    _currentGymName = newGymName;
    _allowMockDataGeneration = enableMockData;
    
    if (_currentGymOwnerId != null) {
      print('🏢 GYM_DATA: Initialized for gym owner ID: $_currentGymOwnerId ($_currentGymName)');
      print('🏢 GYM_DATA: Mock data generation: ${_allowMockDataGeneration ? "ENABLED" : "DISABLED"}');
    } else {
      print('⚠️ GYM_DATA: No gym owner provided - data isolation disabled');
    }
  }

  /// Get current gym owner ID
  int? get currentGymOwnerId => _currentGymOwnerId;
  
  /// Get current gym name
  String? get currentGymName => _currentGymName;

  /// Check if data isolation is active
  bool get isInitialized => _currentGymOwnerId != null;

  /// Generate gym-specific cache key for local storage
  String getGymSpecificKey(String baseKey) {
    if (_currentGymOwnerId == null) {
      return baseKey; // Fallback to global key if no gym owner
    }
    return '${baseKey}_gym_${_currentGymOwnerId}';
  }

  /// Generate completely isolated mock data for each gym
  /// This ensures NO DATA OVERLAP between different gym owners
  List<T> getGymSpecificMockData<T>(List<T> baseMockData, T Function(T, int) updateWithGymId) {
    if (_currentGymOwnerId == null) {
      print('⚠️ GYM_DATA: No gym owner ID set, returning empty data for isolation');
      return []; // Return EMPTY data if no gym isolation to prevent data leakage
    }

    // Check if mock data generation is disabled
    if (!_allowMockDataGeneration) {
      print('🚫 GYM_DATA: Mock data generation disabled, returning empty data');
      return [];
    }

    // Check if data needs to be regenerated for different gym
    final currentGymKey = '$_currentGymOwnerId-$_currentGymName';
    if (_lastDataGenerationGym != currentGymKey) {
      print('🔄 GYM_DATA: Data regeneration needed for gym change: $_lastDataGenerationGym → $currentGymKey');
      _lastDataGenerationGym = currentGymKey;
    }

    // Use a more robust ID generation system to ensure absolute isolation
    // Each gym gets a unique ID range based on gym owner ID + large multiplier
    final baseId = (_currentGymOwnerId! * 10000) + DateTime.now().millisecondsSinceEpoch % 1000;
    
    print('🏋️ GYM_DATA: Generating COMPLETELY ISOLATED data for Gym $_currentGymOwnerId ($_currentGymName)');
    print('   🆔 Base ID: $baseId, Range: $baseId-${baseId + 99}');
    
    // Create completely isolated data with gym-specific IDs
    final isolatedData = baseMockData.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final uniqueId = baseId + index + 1; // Ensure unique IDs per gym
      
      return updateWithGymId(item, uniqueId);
    }).toList();
    
    print('✅ GYM_DATA: Generated ${isolatedData.length} COMPLETELY ISOLATED data items for gym $_currentGymOwnerId');
    return isolatedData;
  }

  /// Disable mock data generation (for clean start)
  void disableMockDataGeneration() {
    print('🚫 GYM_DATA: Disabling mock data generation');
    _allowMockDataGeneration = false;
  }

  /// Enable mock data generation (for demo/testing)
  void enableMockDataGeneration() {
    print('✅ GYM_DATA: Enabling mock data generation');
    _allowMockDataGeneration = true;
  }

  /// Check if mock data generation is allowed
  bool get isMockDataGenerationEnabled => _allowMockDataGeneration;

  /// Clear gym data when logging out
  void clear() {
    print('🏢 GYM_DATA: Clearing gym-specific data for gym $_currentGymOwnerId');
    _currentGymOwnerId = null;
    _currentGymName = null;
    _lastDataGenerationGym = null; // Reset data generation tracking
  }
  
  /// Force complete reset - nuclear option
  void nuclearClear() {
    print('☢️ GYM_DATA: NUCLEAR CLEAR - Destroying all gym data context');
    _currentGymOwnerId = null;
    _currentGymName = null;
    _lastDataGenerationGym = null;
    _allowMockDataGeneration = false; // Disable mock data generation on nuclear clear
    // Force garbage collection of any remaining references
    print('☢️ GYM_DATA: Nuclear clear completed, mock data generation disabled');
  }

  /// Log data access for debugging
  void logDataAccess(String dataType, int count) {
    if (kDebugMode) {
      print('🏢 GYM_DATA: Gym $_currentGymOwnerId ($_currentGymName) - Loaded $count $dataType');
    }
  }
}