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

  Future<void> fetchEquipment() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔧 EQUIPMENT: Fetching all equipment...');
      _equipment = await _apiService.getEquipment();
      print('✅ EQUIPMENT: Loaded ${_equipment.length} equipment items from Django backend');
      
      // Don't create mock data - use real backend data only
    } catch (e) {
      print('💥 EQUIPMENT ERROR: $e');
      
      // Handle network errors with user-friendly messages
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      
      // Only use mock data if backend is completely unreachable (network error)
      // Don't create mock data if backend returns 401, 403, or empty arrays
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed')) {
        print('🔌 EQUIPMENT: Backend unreachable, using mock data');
        _createMockEquipment();
      } else {
        print('🔌 EQUIPMENT: Backend reachable but returned error - no mock data');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWorkingEquipment() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('🔧 EQUIPMENT: Fetching working equipment...');
      _workingEquipment = await _apiService.getWorkingEquipment();
      print('✅ EQUIPMENT: Loaded ${_workingEquipment.length} working equipment items');
    } catch (e) {
      print('💥 EQUIPMENT ERROR: $e');
      
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
      print('➕ EQUIPMENT: Adding new equipment: ${equipment.name}');
      
      // For now, add to local list (API integration would go here)
      final newEquipment = Equipment(
        id: DateTime.now().millisecondsSinceEpoch,
        name: equipment.name,
        equipmentType: equipment.equipmentType,
        brand: equipment.brand,
        purchaseDate: equipment.purchaseDate,
        warrantyExpiry: equipment.warrantyExpiry,
        isWorking: equipment.isWorking,
        maintenanceNotes: equipment.maintenanceNotes,
      );
      
      _equipment.add(newEquipment);
      notifyListeners();
      
      print('✅ EQUIPMENT: Successfully added ${equipment.name}');
      return true;
    } catch (e) {
      print('💥 EQUIPMENT ADD ERROR: $e');
      _errorMessage = 'Failed to add equipment: $e';
      return false;
    }
  }

  Future<bool> updateEquipment(Equipment equipment) async {
    try {
      print('📝 EQUIPMENT: Updating equipment: ${equipment.name}');
      
      final index = _equipment.indexWhere((e) => e.id == equipment.id);
      if (index != -1) {
        _equipment[index] = equipment;
        notifyListeners();
        print('✅ EQUIPMENT: Successfully updated ${equipment.name}');
        return true;
      } else {
        _errorMessage = 'Equipment not found';
        return false;
      }
    } catch (e) {
      print('💥 EQUIPMENT UPDATE ERROR: $e');
      _errorMessage = 'Failed to update equipment: $e';
      return false;
    }
  }

  Future<bool> deleteEquipment(int equipmentId) async {
    try {
      print('🗑️ EQUIPMENT: Deleting equipment ID: $equipmentId');
      
      _equipment.removeWhere((e) => e.id == equipmentId);
      notifyListeners();
      
      print('✅ EQUIPMENT: Successfully deleted equipment');
      return true;
    } catch (e) {
      print('💥 EQUIPMENT DELETE ERROR: $e');
      _errorMessage = 'Failed to delete equipment: $e';
      return false;
    }
  }

  Future<bool> updateMaintenanceStatus(int equipmentId, bool isWorking, String notes) async {
    try {
      print('🔧 EQUIPMENT: Updating maintenance status for ID: $equipmentId');
      
      final index = _equipment.indexWhere((e) => e.id == equipmentId);
      if (index != -1) {
        final equipment = _equipment[index];
        _equipment[index] = Equipment(
          id: equipment.id,
          name: equipment.name,
          equipmentType: equipment.equipmentType,
          brand: equipment.brand,
          purchaseDate: equipment.purchaseDate,
          warrantyExpiry: equipment.warrantyExpiry,
          isWorking: isWorking,
          maintenanceNotes: notes,
        );
        notifyListeners();
        print('✅ EQUIPMENT: Updated maintenance status');
        return true;
      } else {
        _errorMessage = 'Equipment not found';
        return false;
      }
    } catch (e) {
      print('💥 EQUIPMENT MAINTENANCE ERROR: $e');
      _errorMessage = 'Failed to update maintenance status: $e';
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
    await fetchEquipment();
  }
}