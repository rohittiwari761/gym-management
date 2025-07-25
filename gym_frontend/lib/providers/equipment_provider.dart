import 'package:flutter/foundation.dart';
import '../models/equipment.dart';
import '../services/api_service.dart';
import '../services/offline_handler.dart';
import '../services/gym_data_service.dart';

class EquipmentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Equipment> _equipment = [];
  List<Equipment> _workingEquipment = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  List<Equipment> get equipment => _getFilteredEquipment();
  List<Equipment> get allEquipment => _equipment;
  List<Equipment> get workingEquipment => _workingEquipment;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedStatus => _selectedStatus;

  // Filtered equipment based on search and filters
  List<Equipment> _getFilteredEquipment() {
    List<Equipment> filtered = List.from(_equipment);

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((equipment) {
        return equipment.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               equipment.brand.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               equipment.equipmentType.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((equipment) => 
        equipment.equipmentType.toLowerCase() == _selectedCategory.toLowerCase()
      ).toList();
    }

    // Filter by status
    if (_selectedStatus != 'All') {
      if (_selectedStatus == 'Working') {
        filtered = filtered.where((equipment) => equipment.isWorking).toList();
      } else if (_selectedStatus == 'Maintenance') {
        filtered = filtered.where((equipment) => !equipment.isWorking).toList();
      }
    }

    return filtered;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSelectedStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedStatus = 'All';
    notifyListeners();
  }

  Future<void> fetchEquipment({
    int page = 1,
    bool loadMore = false,
    bool loadAll = true,  // Changed default to true - always load all equipment
  }) async {
    if (!loadMore) {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      List<Equipment> newEquipment;
      
      if (loadAll) {
        // Load all pages with optimized pagination (for full equipment list)
        newEquipment = await _apiService.getAllPaginatedData<Equipment>(
          apiCall: (page, limit) => _apiService.getEquipment(
            page: page, 
            limit: limit,
            excludeImages: true,  // Always exclude images for list view
          ),
          maxPages: 5,  // Increased to 5 pages (75 equipment items max)
          pageSize: 15,  // Keep at 15 per page for performance
        );
      } else {
        // Load single page for faster response (for dashboard/summary)
        newEquipment = await _apiService.getEquipment(
          page: page,
          limit: 15, // Reduced from 50 to 15 items per page
          excludeImages: true, // Exclude images to reduce from 25MB to ~500KB
          status: _selectedStatus,
        );
      }
      
      if (loadMore && page > 1) {
        // Append new items for pagination
        _equipment.addAll(newEquipment);
      } else {
        // Replace all items for initial load
        _equipment = newEquipment;
      }
      
      // Update working equipment list
      _workingEquipment = _equipment.where((eq) => eq.isWorking).toList();
      
      // Equipment loaded successfully
      
    } catch (e) {
      // Handle network errors with user-friendly messages
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      
      // Specific error handling for different error types
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _errorMessage = 'Authentication expired. Please login again.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        _errorMessage = 'Access denied. Please check your permissions.';
      } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        _errorMessage = 'Equipment endpoint not found. Please contact support.';
      } else if (e.toString().contains('500') || e.toString().contains('Internal Server Error')) {
        _errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed') ||
          e.toString().contains('TimeoutException')) {
        _errorMessage = 'Network connection error. Please check your internet connection.';
        _createMockEquipment(); // Only use mock data for network errors
      } else {
        _errorMessage = 'Failed to load equipment. Please try again.';
      }
      
      if (kDebugMode) print('Equipment fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load equipment image separately when needed (for detail view)
  Future<String?> loadEquipmentImage(int equipmentId) async {
    try {
      // Loading equipment image
      
      // Call equipment detail endpoint with images included
      final response = await _apiService.getEquipment(
        page: 1,
        limit: 1,
        excludeImages: false, // Include images for detail view
      );
      
      final equipment = response.firstWhere(
        (eq) => eq.id == equipmentId,
        orElse: () => throw Exception('Equipment not found'),
      );
      
      print('✅ EQUIPMENT: Image loaded for equipment $equipmentId');
      return equipment.imageUrl; // Assuming Equipment model has imageUrl field
      
    } catch (e) {
      print('❌ EQUIPMENT: Failed to load image for equipment $equipmentId: $e');
      return null;
    }
  }

  Future<void> fetchWorkingEquipment() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _workingEquipment = await _apiService.getWorkingEquipment();
    } catch (e) {
      
      // Handle network errors with user-friendly messages
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      
      // Fallback to working equipment from existing list
      _workingEquipment = _equipment.where((e) => e.isWorking).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addEquipment(Equipment equipment) async {
    try {
      _setLoading(true);
      
      // Call API to create equipment on backend
      final success = await _apiService.createEquipment(equipment);
      
      if (success) {
        // Refresh data from backend to get the actual ID and updated list
        await fetchEquipment(loadAll: true);
        _errorMessage = '';
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Failed to add equipment to server';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to add equipment: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateEquipment(Equipment equipment) async {
    try {
      _setLoading(true);
      
      // Call API to update equipment on backend
      final success = await _apiService.updateEquipment(equipment);
      
      if (success) {
        // Update local data if API call was successful
        final index = _equipment.indexWhere((e) => e.id == equipment.id);
        if (index != -1) {
          _equipment[index] = equipment;
          _errorMessage = '';
        }
        
        // Refresh working equipment list if status changed
        if (equipment.isWorking) {
          final workingIndex = _workingEquipment.indexWhere((e) => e.id == equipment.id);
          if (workingIndex != -1) {
            _workingEquipment[workingIndex] = equipment;
          } else {
            _workingEquipment.add(equipment);
          }
        } else {
          _workingEquipment.removeWhere((e) => e.id == equipment.id);
        }
        
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Failed to update equipment on server';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update equipment: $e';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteEquipment(int equipmentId) async {
    try {
      _setLoading(true);
      print('🗑️ EQUIPMENT: Starting deletion of equipment ID: $equipmentId');
      
      // Store the equipment being deleted for logging
      final equipmentToDelete = _equipment.firstWhere(
        (e) => e.id == equipmentId,
        orElse: () => Equipment(
          id: equipmentId,
          name: 'Unknown Equipment',
          equipmentType: '',
          brand: '',
          purchaseDate: DateTime.now(),
          warrantyExpiry: DateTime.now(),
          isWorking: true,
        ),
      );
      print('🗑️ EQUIPMENT: Deleting "${equipmentToDelete.name}" (ID: $equipmentId)');
      
      // Call API to delete equipment on backend
      final success = await _apiService.deleteEquipment(equipmentId);
      print('🗑️ EQUIPMENT: API deletion result: $success');
      
      if (success) {
        // Refresh the full list from server to ensure consistency
        print('🗑️ EQUIPMENT: Deletion successful, refreshing full list from server...');
        
        try {
          // Fetch fresh data from server to get accurate count and list
          await fetchEquipment(loadAll: true);
          print('🗑️ EQUIPMENT: Refreshed equipment list - now showing ${_equipment.length} items');
          
          _errorMessage = '';
          _setLoading(false);
          return true;
        } catch (e) {
          print('❌ EQUIPMENT: Failed to refresh after deletion: $e');
          // Fallback: remove from local data if refresh fails
          _equipment.removeWhere((e) => e.id == equipmentId);
          _workingEquipment.removeWhere((e) => e.id == equipmentId);
          
          print('🗑️ EQUIPMENT: Using fallback local removal - main list: ${_equipment.length} items');
          
          _errorMessage = '';
          _setLoading(false);
          notifyListeners();
          return true;
        }
      } else {
        _errorMessage = 'Failed to delete equipment from server. Equipment may still exist on server.';
        print('❌ EQUIPMENT: Server deletion failed for ID: $equipmentId');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to delete equipment: $e';
      print('❌ EQUIPMENT: Exception during deletion: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateMaintenanceStatus(int equipmentId, bool isWorking, String notes) async {
    try {
      print('🔧 EQUIPMENT: Updating maintenance status for ID: $equipmentId');
      _setLoading(true);
      
      final index = _equipment.indexWhere((e) => e.id == equipmentId);
      if (index != -1) {
        final equipment = _equipment[index];
        final updatedEquipment = Equipment(
          id: equipment.id,
          name: equipment.name,
          equipmentType: equipment.equipmentType,
          brand: equipment.brand,
          purchaseDate: equipment.purchaseDate,
          warrantyExpiry: equipment.warrantyExpiry,
          isWorking: isWorking,
          maintenanceNotes: notes,
        );
        
        // Call API to update equipment on backend
        final success = await _apiService.updateEquipment(updatedEquipment);
        
        if (success) {
          // Update local data if API call was successful
          _equipment[index] = updatedEquipment;
          
          // Update working equipment list
          if (isWorking) {
            final workingIndex = _workingEquipment.indexWhere((e) => e.id == equipmentId);
            if (workingIndex != -1) {
              _workingEquipment[workingIndex] = updatedEquipment;
            } else {
              _workingEquipment.add(updatedEquipment);
            }
          } else {
            _workingEquipment.removeWhere((e) => e.id == equipmentId);
          }
          
          _errorMessage = '';
          print('✅ EQUIPMENT: Updated maintenance status');
          _setLoading(false);
          return true;
        } else {
          _errorMessage = 'Failed to update maintenance status on server';
          _setLoading(false);
          return false;
        }
      } else {
        _errorMessage = 'Equipment not found';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      print('💥 EQUIPMENT MAINTENANCE ERROR: $e');
      _errorMessage = 'Failed to update maintenance status: $e';
      _setLoading(false);
      return false;
    }
  }

  void _createMockEquipment() {
    final gymDataService = GymDataService();
    final gymName = gymDataService.currentGymName ?? 'Sample Gym';
    
    print('🔧 EQUIPMENT: Creating mock equipment data for gym: $gymName');
    
    final baseMockEquipment = [
      Equipment(
        id: 1,
        name: 'Treadmill Pro',
        equipmentType: 'Cardio',
        brand: 'TechFit',
        purchaseDate: DateTime(2023, 1, 15),
        warrantyExpiry: DateTime(2026, 1, 15),
        isWorking: true,
        maintenanceNotes: 'Regular maintenance completed',
      ),
      Equipment(
        id: 2,
        name: 'Leg Press Machine',
        equipmentType: 'Strength',
        brand: 'IronMax',
        purchaseDate: DateTime(2022, 8, 20),
        warrantyExpiry: DateTime(2025, 8, 20),
        isWorking: false,
        maintenanceNotes: 'Hydraulic system needs repair',
      ),
      Equipment(
        id: 3,
        name: 'Rowing Machine',
        equipmentType: 'Cardio',
        brand: 'AquaFit',
        purchaseDate: DateTime(2023, 3, 10),
        warrantyExpiry: DateTime(2026, 3, 10),
        isWorking: true,
        maintenanceNotes: '',
      ),
      Equipment(
        id: 4,
        name: 'Dumbbells Set',
        equipmentType: 'Free Weights',
        brand: 'StrongGrip',
        purchaseDate: DateTime(2022, 5, 5),
        warrantyExpiry: DateTime(2027, 5, 5),
        isWorking: true,
        maintenanceNotes: 'Excellent condition',
      ),
      Equipment(
        id: 5,
        name: 'Lat Pulldown',
        equipmentType: 'Strength',
        brand: 'PowerLift',
        purchaseDate: DateTime(2023, 6, 12),
        warrantyExpiry: DateTime(2026, 6, 12),
        isWorking: false,
        maintenanceNotes: 'Cable replacement required',
      ),
    ];
    
    // Use gym-specific data isolation with unique IDs
    final gymSpecificEquipment = gymDataService.getGymSpecificMockData<Equipment>(
      baseMockEquipment,
      (equipment, uniqueId) => Equipment(
        id: uniqueId, // Each gym gets completely unique ID range
        name: '${equipment.name} (${gymName})',
        equipmentType: equipment.equipmentType,
        brand: equipment.brand,
        purchaseDate: equipment.purchaseDate,
        warrantyExpiry: equipment.warrantyExpiry,
        isWorking: equipment.isWorking,
        maintenanceNotes: equipment.maintenanceNotes,
      ),
    );
    
    _equipment = gymSpecificEquipment;
    gymDataService.logDataAccess('equipment items', gymSpecificEquipment.length);
  }

  int get totalEquipment => _equipment.length;
  int get workingEquipmentCount => _equipment.where((e) => e.isWorking).length;
  int get maintenanceEquipmentCount => _equipment.where((e) => !e.isWorking).length;
  
  List<String> get equipmentTypes {
    final types = _equipment.map((equipment) => equipment.equipmentType).toSet().toList();
    types.insert(0, 'All');
    return types;
  }

  List<String> get equipmentBrands => _equipment
      .map((equipment) => equipment.brand)
      .toSet()
      .toList();

  // Get equipment statistics
  Map<String, int> get equipmentByType {
    final Map<String, int> stats = {};
    for (final equipment in _equipment) {
      stats[equipment.equipmentType] = (stats[equipment.equipmentType] ?? 0) + 1;
    }
    return stats;
  }

  List<Equipment> get expiringSoonWarranty {
    final oneMonthFromNow = DateTime.now().add(const Duration(days: 30));
    return _equipment.where((e) => 
      e.warrantyExpiry.isBefore(oneMonthFromNow) && 
      e.warrantyExpiry.isAfter(DateTime.now())
    ).toList();
  }

  List<Equipment> get expiredWarranty => _equipment.where((e) => 
    e.warrantyExpiry.isBefore(DateTime.now())
  ).toList();

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  /// Clear all equipment data and reset for new gym context
  void clearAllData() {
    print('🧹 EQUIPMENT: Clearing all equipment data for new gym context');
    _equipment.clear();
    _workingEquipment.clear();
    _errorMessage = '';
    _isLoading = false;
    _searchQuery = '';
    _selectedCategory = 'All';
    _selectedStatus = 'All';
    notifyListeners();
  }
  
  /// Force refresh equipment data for current gym
  Future<void> forceRefresh() async {
    print('🔄 EQUIPMENT: Force refreshing equipment data');
    clearAllData();
    await fetchEquipment(loadAll: true);
  }

  /// Set loading state and notify listeners
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}