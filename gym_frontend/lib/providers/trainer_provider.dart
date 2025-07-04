import 'package:flutter/foundation.dart';
import '../models/trainer.dart';
import '../models/member.dart'; // For User model
import '../services/api_service.dart';
import '../services/offline_handler.dart';
import '../services/gym_data_service.dart';

class TrainerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Trainer> _trainers = [];
  List<Trainer> _availableTrainers = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<Trainer> get trainers => _trainers;
  List<Trainer> get availableTrainers => _trainers.where((t) => t.isAvailable).toList();
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchTrainers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('👨‍💼 TRAINERS: Fetching trainers...');
      _trainers = await _apiService.getTrainers();
      print('✅ TRAINERS: Loaded ${_trainers.length} trainers from Django backend');
      
      // Update available trainers list
      _availableTrainers = _trainers.where((t) => t.isAvailable).toList();
      
      // Don't create mock data - use real backend data only
    } catch (e) {
      print('💥 TRAINERS ERROR: $e');
      
      // Handle network errors with user-friendly messages
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      
      // Only use mock data if backend is completely unreachable (network error)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed')) {
        print('🔌 TRAINERS: Backend unreachable, using mock data');
        _createMockTrainers();
      } else {
        print('🔌 TRAINERS: Backend reachable but returned error - no mock data');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAvailableTrainers() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      print('👨‍💼 TRAINERS: Fetching available trainers...');
      _availableTrainers = await _apiService.getAvailableTrainers();
      print('✅ TRAINERS: Loaded ${_availableTrainers.length} available trainers');
    } catch (e) {
      print('💥 TRAINERS ERROR: $e');
      
      // Handle network errors with user-friendly messages
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      
      // Fallback to available trainers from existing list
      _availableTrainers = _trainers.where((t) => t.isAvailable).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  int get totalTrainers => _trainers.length;
  int get availableTrainersCount => _availableTrainers.length;
  
  List<String> get specializations => _trainers
      .map((trainer) => trainer.specialization)
      .toSet()
      .toList();

  Future<bool> createTrainer({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String specialization,
    required int experienceYears,
    required String certification,
    required double hourlyRate,
    required bool isAvailable,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final trainer = await _apiService.createTrainer(
        firstName: firstName,
        lastName: lastName,
        email: email,
        phone: phone,
        specialization: specialization,
        experienceYears: experienceYears,
        certification: certification,
        hourlyRate: hourlyRate,
        isAvailable: isAvailable,
      );

      _trainers.insert(0, trainer);
      if (trainer.isAvailable) {
        _availableTrainers.insert(0, trainer);
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      // Handle network errors with user-friendly messages
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTrainerAvailability(int trainerId, bool isAvailable) async {
    try {
      _errorMessage = '';
      
      final success = await _apiService.updateTrainerAvailability(trainerId, isAvailable);
      
      if (success) {
        final trainerIndex = _trainers.indexWhere((t) => t.id == trainerId);
        if (trainerIndex != -1) {
          // Update the trainer in the main list
          final updatedTrainer = Trainer(
            id: _trainers[trainerIndex].id,
            user: _trainers[trainerIndex].user,
            phone: _trainers[trainerIndex].phone,
            specialization: _trainers[trainerIndex].specialization,
            experienceYears: _trainers[trainerIndex].experienceYears,
            certification: _trainers[trainerIndex].certification,
            hourlyRate: _trainers[trainerIndex].hourlyRate,
            isAvailable: isAvailable,
          );
          
          _trainers[trainerIndex] = updatedTrainer;
          
          // Update available trainers list
          _availableTrainers.removeWhere((t) => t.id == trainerId);
          if (isAvailable) {
            _availableTrainers.add(updatedTrainer);
          }
          
          notifyListeners();
        }
      }
      
      return success;
    } catch (e) {
      // Handle network errors with user-friendly messages
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      
      notifyListeners();
      return false;
    }
  }

  void _createMockTrainers() {
    final gymDataService = GymDataService();
    final gymName = gymDataService.currentGymName ?? 'Sample Gym';
    
    print('👨‍💼 TRAINERS: Creating mock trainer data for gym: $gymName');
    
    final baseMockTrainers = [
      Trainer(
        id: 1,
        user: User(
          id: 101,
          username: 'john.trainer@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'john.trainer@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'John',
          lastName: 'Smith',
        ),
        phone: '+91 9876543210',
        specialization: 'Strength Training',
        experienceYears: 5,
        certification: 'ACSM Certified Personal Trainer',
        hourlyRate: 1500.0,
        isAvailable: true,
      ),
      Trainer(
        id: 2,
        user: User(
          id: 102,
          username: 'sarah.trainer@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'sarah.trainer@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'Sarah',
          lastName: 'Johnson',
        ),
        phone: '+91 9876543211',
        specialization: 'Yoga & Flexibility',
        experienceYears: 8,
        certification: 'RYT 500 Yoga Alliance',
        hourlyRate: 1200.0,
        isAvailable: true,
      ),
      Trainer(
        id: 3,
        user: User(
          id: 103,
          username: 'mike.trainer@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'mike.trainer@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'Mike',
          lastName: 'Wilson',
        ),
        phone: '+91 9876543212',
        specialization: 'Cardio & HIIT',
        experienceYears: 3,
        certification: 'NASM Certified Trainer',
        hourlyRate: 1000.0,
        isAvailable: false,
      ),
      Trainer(
        id: 4,
        user: User(
          id: 104,
          username: 'lisa.trainer@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'lisa.trainer@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'Lisa',
          lastName: 'Brown',
        ),
        phone: '+91 9876543213',
        specialization: 'Nutrition & Wellness',
        experienceYears: 6,
        certification: 'ISSA Nutrition Specialist',
        hourlyRate: 1300.0,
        isAvailable: true,
      ),
    ];
    
    // Use gym-specific data isolation with unique IDs
    final gymSpecificTrainers = gymDataService.getGymSpecificMockData<Trainer>(
      baseMockTrainers,
      (trainer, uniqueId) => Trainer(
        id: uniqueId, // Each gym gets completely unique ID range
        user: User(
          id: uniqueId + 20000, // Trainer user IDs offset to prevent conflicts
          username: '${trainer.user?.firstName?.toLowerCase()}.${trainer.user?.lastName?.toLowerCase()}@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: '${trainer.user?.firstName?.toLowerCase()}.${trainer.user?.lastName?.toLowerCase()}@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: trainer.user?.firstName ?? '',
          lastName: trainer.user?.lastName ?? '',
        ),
        phone: trainer.phone,
        specialization: trainer.specialization,
        experienceYears: trainer.experienceYears,
        certification: trainer.certification,
        hourlyRate: trainer.hourlyRate,
        isAvailable: trainer.isAvailable,
      ),
    );
    
    _trainers = gymSpecificTrainers;
    _availableTrainers = gymSpecificTrainers.where((t) => t.isAvailable).toList();
    gymDataService.logDataAccess('trainers', gymSpecificTrainers.length);
  }
  
  /// Clear all trainer data and reset for new gym context
  void clearAllData() {
    print('🧹 TRAINERS: Clearing all trainer data for new gym context');
    _trainers.clear();
    _availableTrainers.clear();
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
  }
  
  /// Force refresh trainer data for current gym
  Future<void> forceRefresh() async {
    print('🔄 TRAINERS: Force refreshing trainer data');
    clearAllData();
    await fetchTrainers();
  }
}