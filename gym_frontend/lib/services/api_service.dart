import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/member.dart';
import '../models/trainer.dart';
import '../models/equipment.dart';
import '../models/workout_session.dart';
import '../security/secure_http_client.dart';
import '../security/security_config.dart';
import '../security/input_validator.dart';
import '../utils/timezone_utils.dart';
import '../utils/debouncer.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final SecureHttpClient _httpClient = SecureHttpClient();
  final CacheManager<List<Member>> _membersCache = CacheManager();
  final CacheManager<List<Trainer>> _trainersCache = CacheManager();
  final CacheManager<List<Equipment>> _equipmentCache = CacheManager();
  final Throttler _requestThrottler = Throttler(duration: const Duration(milliseconds: 500));

  /// Initialize API service
  void initialize() {
    _httpClient.initialize();
    SecurityConfig.logSecurityEvent('API_SERVICE_INITIALIZED', {});
  }

  /// Secure error handling
  Map<String, dynamic> _handleSecureError(String operation, dynamic error) {
    final sanitizedError = error.toString().replaceAll(RegExp(r'[<>"\x27]'), '');
    SecurityConfig.logSecurityEvent('API_ERROR', {
      'operation': operation,
      'error_type': error.runtimeType.toString(),
    });
    
    // Handle specific error types with user-friendly messages
    String userMessage = 'Service temporarily unavailable. Please try again.';
    
    if (sanitizedError.contains('SocketException') || 
        sanitizedError.contains('Connection refused') ||
        sanitizedError.contains('Network is unreachable') ||
        sanitizedError.contains('Connection failed')) {
      userMessage = 'Unable to connect to server. Please check your internet connection and try again.';
    } else if (sanitizedError.contains('TimeoutException') ||
               sanitizedError.contains('timeout')) {
      userMessage = 'Request timed out. Please check your connection and try again.';
    } else if (sanitizedError.contains('HandshakeException') ||
               sanitizedError.contains('Certificate')) {
      userMessage = 'Secure connection failed. Please try again later.';
    }
    
    return {
      'success': false,
      'message': userMessage,
      'details': kDebugMode ? sanitizedError : null,
    };
  }

  /// Validate and sanitize member data
  Map<String, dynamic> _validateMemberData(Member member) {
    if (member.user?.email != null) {
      final emailValidation = InputValidator.validateEmail(member.user!.email);
      if (!emailValidation.isValid) {
        return {'valid': false, 'error': emailValidation.message};
      }
    }

    final phoneValidation = InputValidator.validatePhoneNumber(member.phoneNumber);
    if (!phoneValidation.isValid) {
      return {'valid': false, 'error': phoneValidation.message};
    }

    if (member.user?.firstName != null) {
      final firstNameValidation = InputValidator.validateName(member.user!.firstName, fieldName: 'First name');
      if (!firstNameValidation.isValid) {
        return {'valid': false, 'error': firstNameValidation.message};
      }
    }

    if (member.user?.lastName != null) {
      final lastNameValidation = InputValidator.validateName(member.user!.lastName, fieldName: 'Last name');
      if (!lastNameValidation.isValid) {
        return {'valid': false, 'error': lastNameValidation.message};
      }
    }

    return {'valid': true};
  }

  // Members API
  Future<List<Member>> getMembers({
    int page = 1,
    int limit = 25,  // Reduced from unlimited to 25 per page
    List<String>? excludeFields,
  }) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'members',
        'method': 'GET',
      });

      // Build query parameters to get complete member data
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': limit.toString(),  // Changed from 'limit' to 'page_size' for backend compatibility
        // Removed 'minimal': 'true' to get complete member data including address and emergency contact
      };
      
      // Exclude heavy fields that aren't needed for list view (for backward compatibility)
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      }
      
      print('👥 MEMBERS: Requesting page $page with page_size $limit (complete data)');

      final response = await _httpClient.get(
        'members/', 
        requireAuth: true,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        print('🔍 MEMBERS: Response data type: ${responseData.runtimeType}');
        print('🔍 MEMBERS: Response data: ${responseData.toString()}');
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
          final totalCount = responseData['count'] ?? jsonList.length;
          final nextPage = responseData['next'];
          print('✅ MEMBERS: Loaded ${jsonList.length} items (Total: $totalCount, Has Next: ${nextPage != null})');
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
          print('✅ MEMBERS: Loaded ${jsonList.length} items (direct list)');
        } else {
          print('❌ MEMBERS: Unexpected response format: ${responseData.runtimeType}');
          throw Exception('Unexpected response format: expected Map with results or List, got ${responseData.runtimeType}');
        }
        
        SecurityConfig.logSecurityEvent('MEMBERS_LOADED', {
          'count': jsonList.length,
          'page': page,
          'limit': limit,
        });
        
        // Parse each member individually with error handling
        final List<Member> members = [];
        for (int i = 0; i < jsonList.length; i++) {
          try {
            final memberJson = jsonList[i];
            print('🔍 MEMBERS: Parsing member $i: ${memberJson.toString()}');
            final member = Member.fromJson(memberJson);
            members.add(member);
          } catch (e) {
            print('❌ MEMBERS: Failed to parse member $i: $e');
            print('❌ MEMBERS: Member JSON: ${jsonList[i]}');
            // Continue parsing other members, skip the problematic one
          }
        }
        
        print('✅ MEMBERS: Successfully parsed ${members.length}/${jsonList.length} members');
        return members;
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load members');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('MEMBERS_LOAD_ERROR', {
        'error': e.toString(),
      });
      throw Exception('Failed to load members. Please try again.');
    }
  }

  Future<Member> createMember(Member member) async {
    try {
      // Validate member data
      final validation = _validateMemberData(member);
      if (!validation['valid']) {
        throw Exception(validation['error']);
      }

      SecurityConfig.logSecurityEvent('MEMBER_CREATION_REQUEST', {
        'email': member.user?.email != null ? InputValidator.sanitizeInput(member.user!.email) : 'no_email',
      });

      // Sanitize member data
      User? sanitizedUser;
      if (member.user != null) {
        sanitizedUser = User(
          id: member.user!.id,
          username: InputValidator.sanitizeInput(member.user!.username),
          email: InputValidator.sanitizeInput(member.user!.email),
          firstName: InputValidator.sanitizeInput(member.user!.firstName),
          lastName: InputValidator.sanitizeInput(member.user!.lastName),
        );
      }

      final sanitizedMember = Member(
        id: member.id,
        user: sanitizedUser,
        phone: InputValidator.sanitizeInput(member.phoneNumber),
        dateOfBirth: member.dateOfBirth,
        membershipType: member.membershipType,
        joinDate: member.joinDate,
        membershipExpiry: member.membershipExpiry,
        isActive: member.isActive,
        emergencyContactName: member.emergencyContactName != null ? InputValidator.sanitizeInput(member.emergencyContactName!) : '',
        emergencyContactPhone: member.emergencyContactPhone != null ? InputValidator.sanitizeInput(member.emergencyContactPhone!) : '',
      );

      final response = await _httpClient.post(
        'members/',
        body: sanitizedMember.toJson(),
      );

      if (response.isSuccess && response.data != null) {
        SecurityConfig.logSecurityEvent('MEMBER_CREATED', {
          'memberId': response.data!['id']?.toString(),
        });
        return Member.fromJson(response.data!);
      } else {
        throw Exception(response.errorMessage ?? 'Failed to create member');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('MEMBER_CREATION_ERROR', {
        'error': e.toString(),
      });
      throw Exception('Failed to create member. Please check your input and try again.');
    }
  }

  // Trainers API
  Future<List<Trainer>> getTrainers({
    int page = 1,
    int limit = 20,  // Reduced limit for trainers
    List<String>? excludeFields,
  }) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'trainers',
        'method': 'GET',
      });

      // Build query parameters to optimize response size
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Exclude heavy fields that aren't needed for list view
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      } else {
        // Default exclusions for performance
        queryParams['exclude'] = 'profile_picture,detailed_bio,certifications_data,workout_sessions';
      }
      
      print('🏋️ TRAINERS: Requesting page $page with limit $limit (exclude: ${queryParams['exclude']})');

      final response = await _httpClient.get(
        'trainers/', 
        requireAuth: true,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
          final totalCount = responseData['count'] ?? jsonList.length;
          final nextPage = responseData['next'];
          print('✅ TRAINERS: Loaded ${jsonList.length} items (Total: $totalCount, Has Next: ${nextPage != null})');
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
          print('✅ TRAINERS: Loaded ${jsonList.length} items (direct list)');
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.map((json) => Trainer.fromJson(json)).toList();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load trainers');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('TRAINERS_LOAD_ERROR', {
        'error': e.toString(),
      });
      throw Exception('Failed to load trainers. Please try again.');
    }
  }

  Future<List<Trainer>> getAvailableTrainers({
    int page = 1,
    int limit = 15,  // Reduced limit for better performance
    List<String>? excludeFields,
  }) async {
    try {
      // Build query parameters to optimize response size
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Exclude heavy fields that aren't needed for available trainers list
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      } else {
        // Default exclusions for performance
        queryParams['exclude'] = 'profile_picture,detailed_bio,certifications_data,workout_sessions,training_history';
      }
      
      print('🏋️ AVAILABLE_TRAINERS: Requesting page $page with limit $limit (exclude: ${queryParams['exclude']})');

      final response = await _httpClient.get(
        'trainers/available/', 
        requireAuth: true,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
          final totalCount = responseData['count'] ?? jsonList.length;
          final nextPage = responseData['next'];
          print('✅ AVAILABLE_TRAINERS: Loaded ${jsonList.length} items (Total: $totalCount, Has Next: ${nextPage != null})');
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
          print('✅ AVAILABLE_TRAINERS: Loaded ${jsonList.length} items (direct list)');
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.map((json) => Trainer.fromJson(json)).toList();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load available trainers');
      }
    } catch (e) {
      throw Exception('Failed to load available trainers. Please try again.');
    }
  }

  Future<Trainer> createTrainer({
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
    try {
      // Validate all inputs
      final emailValidation = InputValidator.validateEmail(email);
      if (!emailValidation.isValid) {
        throw Exception(emailValidation.message);
      }

      final phoneValidation = InputValidator.validatePhoneNumber(phone);
      if (!phoneValidation.isValid) {
        throw Exception(phoneValidation.message);
      }

      final firstNameValidation = InputValidator.validateName(firstName, fieldName: 'First name');
      if (!firstNameValidation.isValid) {
        throw Exception(firstNameValidation.message);
      }

      final lastNameValidation = InputValidator.validateName(lastName, fieldName: 'Last name');
      if (!lastNameValidation.isValid) {
        throw Exception(lastNameValidation.message);
      }

      final specializationValidation = InputValidator.validateTextInput(
        specialization,
        maxLength: 100,
        fieldName: 'Specialization',
      );
      if (!specializationValidation.isValid) {
        throw Exception(specializationValidation.message);
      }

      final certificationValidation = InputValidator.validateTextInput(
        certification,
        maxLength: 200,
        fieldName: 'Certification',
      );
      if (!certificationValidation.isValid) {
        throw Exception(certificationValidation.message);
      }

      // Validate numeric inputs
      final experienceValidation = InputValidator.validateNumericInput(
        experienceYears.toString(),
        min: 0,
        max: 50,
        allowDecimals: false,
        fieldName: 'Experience years',
      );
      if (!experienceValidation.isValid) {
        throw Exception(experienceValidation.message);
      }

      final rateValidation = InputValidator.validateNumericInput(
        hourlyRate.toString(),
        min: 0,
        max: 10000,
        fieldName: 'Hourly rate',
      );
      if (!rateValidation.isValid) {
        throw Exception(rateValidation.message);
      }

      SecurityConfig.logSecurityEvent('TRAINER_CREATION_REQUEST', {
        'email': InputValidator.sanitizeInput(email),
      });

      final response = await _httpClient.post('trainers/', body: {
        'user': {
          'first_name': InputValidator.sanitizeInput(firstName),
          'last_name': InputValidator.sanitizeInput(lastName),
          'email': InputValidator.sanitizeInput(email),
          'username': InputValidator.sanitizeInput(email),
        },
        'phone': InputValidator.sanitizeInput(phone),
        'specialization': InputValidator.sanitizeInput(specialization),
        'experience_years': experienceYears,
        'certification': InputValidator.sanitizeInput(certification),
        'hourly_rate': hourlyRate,
        'is_available': isAvailable,
      });

      if (response.isSuccess && response.data != null) {
        SecurityConfig.logSecurityEvent('TRAINER_CREATED', {
          'trainerId': response.data!['id']?.toString(),
        });
        return Trainer.fromJson(response.data!);
      } else {
        throw Exception(response.errorMessage ?? 'Failed to create trainer');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('TRAINER_CREATION_ERROR', {
        'error': e.toString(),
      });
      throw Exception('Failed to create trainer. Please check your input and try again.');
    }
  }

  Future<bool> updateTrainerAvailability(int trainerId, bool isAvailable) async {
    try {
      // Validate trainer ID
      if (trainerId <= 0) {
        throw Exception('Invalid trainer ID');
      }

      SecurityConfig.logSecurityEvent('TRAINER_UPDATE_REQUEST', {
        'trainerId': trainerId.toString(),
        'isAvailable': isAvailable.toString(),
      });

      final response = await _httpClient.patch('trainers/$trainerId/', body: {
        'is_available': isAvailable,
      });

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('TRAINER_UPDATED', {
          'trainerId': trainerId.toString(),
        });
        return true;
      } else {
        throw Exception(response.errorMessage ?? 'Failed to update trainer availability');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('TRAINER_UPDATE_ERROR', {
        'error': e.toString(),
      });
      throw Exception('Failed to update trainer availability. Please try again.');
    }
  }

  // Equipment API
  Future<List<Equipment>> getEquipment({
    int page = 1, 
    int limit = 15,  // Drastically reduced from 50 to 15
    bool excludeImages = true,
    String? status,
    List<String>? excludeFields,
  }) async {
    try {
      // Build query parameters for new optimized backend API
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': limit.toString(),  // Backend expects 'page_size' not 'limit'
      };
      
      // Use minimal serializer for maximum performance (new backend feature)
      if (excludeImages) {
        queryParams['minimal'] = 'true';
      }
      
      // Filter by status if provided
      if (status != null && status.isNotEmpty && status != 'All') {
        queryParams['status'] = status.toLowerCase();
      }
      
      print('🔧 EQUIPMENT: Requesting page $page with page_size $limit (minimal: ${excludeImages ? 'true' : 'false'})');
      
      final response = await _httpClient.get(
        'equipment/', 
        requireAuth: true,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // New optimized paginated response from backend
          jsonList = responseData['results'] as List<dynamic>;
          final totalCount = responseData['count'] ?? jsonList.length;
          final currentPage = responseData['page'] ?? page;
          final pageSize = responseData['page_size'] ?? limit;
          final totalPages = responseData['total_pages'] ?? 1;
          final responseSizeKb = responseData['response_size_kb'];
          
          print('✅ EQUIPMENT: Loaded ${jsonList.length} items (Page: $currentPage/$totalPages, Total: $totalCount)');
          if (responseSizeKb != null) {
            print('📊 EQUIPMENT: Response size: ${responseSizeKb}KB (target: <1MB per request)');
          }
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback for older API)
          jsonList = responseData;
          print('✅ EQUIPMENT: Loaded ${jsonList.length} items (direct list)');
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.map((json) => Equipment.fromJson(json)).toList();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load equipment');
      }
    } catch (e) {
      print('❌ EQUIPMENT: Load failed - ${e.toString()}');
      throw Exception('Failed to load equipment. Please try again.');
    }
  }

  Future<List<Equipment>> getWorkingEquipment({
    int page = 1,
    int limit = 15,  // Optimized limit for working equipment
    List<String>? excludeFields,
  }) async {
    try {
      // Build query parameters for optimized backend API
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'page_size': limit.toString(),  // Backend expects 'page_size'
      };
      
      print('🔧 WORKING_EQUIPMENT: Requesting page $page with page_size $limit');

      final response = await _httpClient.get(
        'equipment/working/', 
        requireAuth: true,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // New optimized paginated response from backend
          jsonList = responseData['results'] as List<dynamic>;
          final totalCount = responseData['count'] ?? jsonList.length;
          final currentPage = responseData['page'] ?? page;
          final pageSize = responseData['page_size'] ?? limit;
          final totalPages = responseData['total_pages'] ?? 1;
          
          print('✅ WORKING_EQUIPMENT: Loaded ${jsonList.length} items (Page: $currentPage/$totalPages, Total: $totalCount)');
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback for older API)
          jsonList = responseData;
          print('✅ WORKING_EQUIPMENT: Loaded ${jsonList.length} items (direct list)');
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.map((json) => Equipment.fromJson(json)).toList();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load working equipment');
      }
    } catch (e) {
      throw Exception('Failed to load working equipment. Please try again.');
    }
  }

  /// Create new equipment
  Future<bool> createEquipment(Equipment equipment) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'equipment',
        'method': 'POST',
      });

      final response = await _httpClient.post(
        'equipment/',
        body: equipment.toJson(),
        requireAuth: true,
      );

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('EQUIPMENT_CREATED', {
          'equipment_name': equipment.name,
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Update existing equipment
  Future<bool> updateEquipment(Equipment equipment) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'equipment/${equipment.id}',
        'method': 'PUT',
      });

      final response = await _httpClient.put(
        'equipment/${equipment.id}/',
        body: equipment.toJson(),
        requireAuth: true,
      );

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('EQUIPMENT_UPDATED', {
          'equipment_id': equipment.id,
          'equipment_name': equipment.name,
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Delete equipment
  Future<bool> deleteEquipment(int equipmentId) async {
    try {
      print('🌐 API: Attempting to delete equipment ID: $equipmentId');
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'equipment/$equipmentId',
        'method': 'DELETE',
      });

      final response = await _httpClient.delete(
        'equipment/$equipmentId/',
        requireAuth: true,
      );

      print('🌐 API: Delete response status: ${response.statusCode}');
      print('🌐 API: Delete response success: ${response.isSuccess}');
      if (response.errorMessage != null) {
        print('🌐 API: Delete error message: ${response.errorMessage}');
      }

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('EQUIPMENT_DELETED', {
          'equipment_id': equipmentId,
        });
        print('✅ API: Equipment $equipmentId deleted successfully');
        return true;
      } else {
        print('❌ API: Failed to delete equipment $equipmentId - Status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ API: Exception during equipment deletion: $e');
      return false;
    }
  }

  // Workout Sessions API
  Future<List<WorkoutSession>> getUpcomingSessions({
    int page = 1,
    int limit = 20,  // Reasonable limit for upcoming sessions
    List<String>? excludeFields,
  }) async {
    try {
      // Build query parameters to optimize response size
      final queryParams = <String, dynamic>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Exclude heavy fields that aren't needed for upcoming sessions list
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      } else {
        // Default exclusions for performance
        queryParams['exclude'] = 'detailed_notes,exercise_logs,performance_metrics,session_recordings,feedback_history';
      }
      
      print('💪 UPCOMING_SESSIONS: Requesting page $page with limit $limit (exclude: ${queryParams['exclude']})');

      final response = await _httpClient.get(
        'workout-sessions/upcoming/', 
        requireAuth: true,
        queryParams: queryParams,
      );

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
          final totalCount = responseData['count'] ?? jsonList.length;
          final nextPage = responseData['next'];
          print('✅ UPCOMING_SESSIONS: Loaded ${jsonList.length} items (Total: $totalCount, Has Next: ${nextPage != null})');
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
          print('✅ UPCOMING_SESSIONS: Loaded ${jsonList.length} items (direct list)');
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.map((json) => WorkoutSession.fromJson(json)).toList();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load upcoming sessions');
      }
    } catch (e) {
      throw Exception('Failed to load upcoming sessions. Please try again.');
    }
  }

  // Secure Attendance API
  Future<Map<String, dynamic>> checkIn(int memberId, {String? notes}) async {
    try {
      // Validate member ID
      if (memberId <= 0) {
        throw Exception('Invalid member ID');
      }

      // Validate notes if provided
      if (notes != null && notes.isNotEmpty) {
        final notesValidation = InputValidator.validateTextInput(
          notes,
          maxLength: 500,
          fieldName: 'Notes',
          allowEmpty: true,
        );
        if (!notesValidation.isValid) {
          throw Exception(notesValidation.message);
        }
      }

      SecurityConfig.logSecurityEvent('CHECK_IN_ATTEMPT', {
        'memberId': memberId.toString(),
      });

      final response = await _httpClient.post('attendance/check_in/', body: {
        'member_id': memberId,
        'notes': notes != null ? InputValidator.sanitizeInput(notes) : null,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('CHECK_IN_SUCCESS', {
          'memberId': memberId.toString(),
        });
        return {'success': true, 'data': response.data};
      } else if (response.statusCode == 400) {
        // Handle special cases for check-in
        final errorMessage = response.errorMessage ?? '';
        if (errorMessage.toLowerCase().contains('already checked in')) {
          SecurityConfig.logSecurityEvent('DUPLICATE_CHECK_IN', {
            'memberId': memberId.toString(),
          });
          return {
            'success': true,
            'data': {'id': DateTime.now().millisecondsSinceEpoch, 'message': 'Multiple check-in allowed'}
          };
        }
        return {'success': false, 'message': errorMessage};
      } else {
        return {'success': false, 'message': response.errorMessage ?? 'Check-in failed'};
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('CHECK_IN_ERROR', {
        'error': e.toString(),
      });
      return _handleSecureError('check_in', e);
    }
  }

  Future<Map<String, dynamic>> checkOut(int memberId, {String? notes}) async {
    try {
      // Validate member ID
      if (memberId <= 0) {
        throw Exception('Invalid member ID');
      }

      // Validate notes if provided
      if (notes != null && notes.isNotEmpty) {
        final notesValidation = InputValidator.validateTextInput(
          notes,
          maxLength: 500,
          fieldName: 'Notes',
          allowEmpty: true,
        );
        if (!notesValidation.isValid) {
          throw Exception(notesValidation.message);
        }
      }

      SecurityConfig.logSecurityEvent('CHECK_OUT_ATTEMPT', {
        'memberId': memberId.toString(),
      });

      final response = await _httpClient.post('attendance/check_out/', body: {
        'member_id': memberId,
        'notes': notes != null ? InputValidator.sanitizeInput(notes) : null,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('CHECK_OUT_SUCCESS', {
          'memberId': memberId.toString(),
        });
        return {'success': true, 'data': response.data};
      } else if (response.statusCode == 400) {
        // Handle special cases for check-out
        final errorMessage = response.errorMessage ?? '';
        if (errorMessage.toLowerCase().contains('not checked in') ||
            errorMessage.toLowerCase().contains('already checked out')) {
          SecurityConfig.logSecurityEvent('LENIENT_CHECK_OUT', {
            'memberId': memberId.toString(),
          });
          return {
            'success': true,
            'data': {'id': DateTime.now().millisecondsSinceEpoch, 'message': 'Checkout allowed'}
          };
        }
        return {'success': false, 'message': errorMessage};
      } else {
        return {'success': false, 'message': response.errorMessage ?? 'Check-out failed'};
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('CHECK_OUT_ERROR', {
        'error': e.toString(),
      });
      return _handleSecureError('check_out', e);
    }
  }

  Future<Map<String, dynamic>> getAttendances({
    DateTime? date,
    int page = 1,
    int limit = 25,  // Limit attendance records for better performance
    List<String>? excludeFields,
  }) async {
    try {
      String endpoint = 'attendance/';
      Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (date != null) {
        // Use IST timezone for date formatting
        final dateStr = TimezoneUtils.getAPIDateString(date);
        queryParams['date'] = dateStr;
      }

      // Exclude heavy fields for attendance list
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      } else {
        // Default exclusions for performance
        queryParams['exclude'] = 'detailed_notes,location_data,biometric_data,session_photos';
      }
      
      print('📋 ATTENDANCES: Requesting page $page with limit $limit for ${date != null ? queryParams['date'] : 'all dates'}');

      final response = await _httpClient.get(endpoint, queryParams: queryParams);

      if (response.isSuccess) {
        // Log pagination info if available
        if (response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          if (responseData.containsKey('count')) {
            final totalCount = responseData['count'];
            final nextPage = responseData['next'];
            print('✅ ATTENDANCES: Loaded page $page (Total: $totalCount, Has Next: ${nextPage != null})');
          }
        }
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': response.errorMessage ?? 'Failed to fetch attendances'};
      }
    } catch (e) {
      return _handleSecureError('get_attendances', e);
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats({
    List<String>? excludeFields,
  }) async {
    try {
      Map<String, dynamic>? queryParams;
      
      // Exclude heavy fields for stats
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams = {'exclude': excludeFields.join(',')};
      } else {
        // Default exclusions for performance - keep only essential stats
        queryParams = {'exclude': 'detailed_breakdowns,hourly_data,member_details,session_data'};
      }
      
      print('📊 ATTENDANCE_STATS: Requesting with exclusions: ${queryParams!['exclude']}');

      final response = await _httpClient.get('attendance/stats/', queryParams: queryParams);

      if (response.isSuccess) {
        print('✅ ATTENDANCE_STATS: Loaded stats successfully');
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': response.errorMessage ?? 'Failed to fetch attendance stats'};
      }
    } catch (e) {
      return _handleSecureError('get_attendance_stats', e);
    }
  }

  Future<Map<String, dynamic>> getTodayAttendances({
    int limit = 50,  // Limit today's attendance for better performance
    List<String>? excludeFields,
  }) async {
    try {
      SecurityConfig.logSecurityEvent('TODAY_ATTENDANCE_REQUEST', {});

      Map<String, dynamic> queryParams = {
        'limit': limit.toString(),
      };

      // Exclude heavy fields for today's attendance
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      } else {
        // Default exclusions for performance
        queryParams['exclude'] = 'detailed_notes,location_data,biometric_data,session_photos,member_photos';
      }
      
      print('📅 TODAY_ATTENDANCES: Requesting limit $limit with exclusions: ${queryParams['exclude']}');

      final response = await _httpClient.get('attendance/today_attendance/', queryParams: queryParams);

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('TODAY_ATTENDANCE_SUCCESS', {});
        // Handle the specific format from today_attendance endpoint
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          final attendances = responseData['attendances'] as List<dynamic>? ?? [];
          print('✅ TODAY_ATTENDANCES: Loaded ${attendances.length} attendance records');
          return {'success': true, 'data': attendances};
        }
        print('✅ TODAY_ATTENDANCES: No attendance data found');
        return {'success': true, 'data': []};
      } else {
        return {'success': false, 'message': response.errorMessage ?? 'Failed to fetch today\'s attendances'};
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('TODAY_ATTENDANCE_ERROR', {
        'error': e.toString(),
      });
      return _handleSecureError('get_today_attendances', e);
    }
  }

  Future<Map<String, dynamic>> getAttendanceAnalytics({
    List<String>? excludeFields,
    int limit = 100,  // Limit analytics data points
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      SecurityConfig.logSecurityEvent('ATTENDANCE_ANALYTICS_REQUEST', {});

      Map<String, dynamic> queryParams = {
        'limit': limit.toString(),
      };
      
      // Date range filtering for performance
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      
      // Exclude heavy analytics fields for performance
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      } else {
        // Default exclusions for performance - exclude detailed breakdowns
        queryParams['exclude'] = 'detailed_hourly_data,member_breakdowns,trainer_analytics,equipment_usage_details,raw_session_data';
      }
      
      print('📊 ATTENDANCE_ANALYTICS: Requesting with limit $limit, exclusions: ${queryParams['exclude']}');

      final response = await _httpClient.get('attendance/attendance_analytics/', queryParams: queryParams);

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('ATTENDANCE_ANALYTICS_SUCCESS', {});
        
        // Log data size for monitoring
        if (response.data != null) {
          final dataSize = response.data.toString().length;
          print('✅ ATTENDANCE_ANALYTICS: Loaded analytics data (${(dataSize / 1024).round()}KB)');
          
          // Warn if data is still large
          if (dataSize > 500000) { // 500KB
            print('⚠️ ATTENDANCE_ANALYTICS: Large response detected (${(dataSize / 1024).round()}KB), consider more exclusions');
          }
        }
        
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': response.errorMessage ?? 'Failed to fetch attendance analytics'};
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('ATTENDANCE_ANALYTICS_ERROR', {
        'error': e.toString(),
      });
      return _handleSecureError('get_attendance_analytics', e);
    }
  }

  /// Get all active trainer-member associations
  Future<List<Map<String, dynamic>>> getActiveTrainerMemberAssociations({
    int page = 1,
    int limit = 20,  // Limit associations for better performance
    List<String>? excludeFields,
    bool loadAll = false,
  }) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'trainer-member-associations/active',
        'method': 'GET',
      });

      Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Exclude heavy fields for association list
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      } else {
        // Default exclusions for performance
        queryParams['exclude'] = 'trainer_photo,member_photo,detailed_notes,training_history,session_records';
      }
      
      print('🔗 TRAINER_ASSOCIATIONS: Requesting page $page with limit $limit, exclusions: ${queryParams['exclude']}');

      final response = await _httpClient.get('trainer-member-associations/active/', 
        queryParams: queryParams, requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
          final totalCount = responseData['count'];
          final nextPage = responseData['next'];
          print('✅ TRAINER_ASSOCIATIONS: Loaded page $page (Total: $totalCount, Has Next: ${nextPage != null})');
          
          // If loadAll is requested and there are more pages, load them
          if (loadAll && nextPage != null && page < 10) { // Safety limit: max 10 pages
            final nextPageData = await getActiveTrainerMemberAssociations(
              page: page + 1, 
              limit: limit, 
              excludeFields: excludeFields,
              loadAll: true,
            );
            jsonList.addAll(nextPageData);
          }
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
          print('✅ TRAINER_ASSOCIATIONS: Loaded ${jsonList.length} associations (direct list)');
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load associations');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('TRAINER_ASSOCIATIONS_LOAD_ERROR', {
        'error': e.toString(),
      });
      throw Exception('Failed to load trainer-member associations. Please try again.');
    }
  }

  /// Get associations for a specific trainer
  Future<List<Map<String, dynamic>>> getTrainerMembers(
    int trainerId, {
    int page = 1,
    int limit = 15,  // Limit trainer members for better performance
    List<String>? excludeFields,
    String? status,
    bool loadAll = false,
  }) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'trainers/$trainerId/members',
        'method': 'GET',
      });

      Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      // Filter by status if provided
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      
      // Exclude heavy fields for trainer members list
      if (excludeFields != null && excludeFields.isNotEmpty) {
        queryParams['exclude'] = excludeFields.join(',');
      } else {
        // Default exclusions for performance
        queryParams['exclude'] = 'member_photo,medical_history,payment_history,session_notes,detailed_progress';
      }
      
      print('👥 TRAINER_MEMBERS: Requesting trainer $trainerId members, page $page with limit $limit');
      print('👥 TRAINER_MEMBERS: Exclusions: ${queryParams['exclude']}');

      final response = await _httpClient.get('trainers/$trainerId/members/', 
        queryParams: queryParams, requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
          final totalCount = responseData['count'];
          final nextPage = responseData['next'];
          print('✅ TRAINER_MEMBERS: Loaded page $page for trainer $trainerId (Total: $totalCount, Has Next: ${nextPage != null})');
          
          // If loadAll is requested and there are more pages, load them
          if (loadAll && nextPage != null && page < 8) { // Safety limit: max 8 pages for trainer members
            final nextPageData = await getTrainerMembers(
              trainerId,
              page: page + 1,
              limit: limit,
              excludeFields: excludeFields,
              status: status,
              loadAll: true,
            );
            jsonList.addAll(nextPageData);
          }
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
          print('✅ TRAINER_MEMBERS: Loaded ${jsonList.length} members for trainer $trainerId (direct list)');
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load trainer members');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('TRAINER_MEMBERS_LOAD_ERROR', {
        'error': e.toString(),
        'trainerId': trainerId,
      });
      throw Exception('Failed to load trainer members. Please try again.');
    }
  }

  /// Associate member with trainer
  Future<bool> associateMemberWithTrainer(int trainerId, int memberId, {String? notes}) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'trainers/$trainerId/associate_member',
        'method': 'POST',
      });

      final data = {
        'member_id': memberId,
        'notes': notes ?? '',
      };

      final response = await _httpClient.post(
        'trainers/$trainerId/associate_member/',
        body: data,
        requireAuth: true,
      );

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('MEMBER_ASSOCIATED', {
          'trainer_id': trainerId,
          'member_id': memberId,
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('MEMBER_ASSOCIATION_ERROR', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Remove member from trainer
  Future<bool> unassociateMemberFromTrainer(int trainerId, int memberId) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'trainers/$trainerId/unassociate_member',
        'method': 'DELETE',
      });

      final response = await _httpClient.delete(
        'trainers/$trainerId/unassociate_member/',
        headers: {'Content-Type': 'application/json'},
        body: {'member_id': memberId},
        requireAuth: true,
      );

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('MEMBER_UNASSOCIATED', {
          'trainer_id': trainerId,
          'member_id': memberId,
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('MEMBER_UNASSOCIATION_ERROR', {
        'error': e.toString(),
      });
      return false;
    }
  }

  /// Get all pages of data with size limits (for comprehensive data loading)
  Future<List<T>> getAllPaginatedData<T>({
    required Future<List<T>> Function(int page, int limit) apiCall,
    int maxPages = 10,  // Limit to prevent infinite loading
    int pageSize = 20,  // Smaller page size for better performance
  }) async {
    List<T> allItems = [];
    int currentPage = 1;
    
    try {
      while (currentPage <= maxPages) {
        print('📄 PAGINATION: Loading page $currentPage (max: $maxPages)');
        
        final pageItems = await apiCall(currentPage, pageSize);
        
        if (pageItems.isEmpty) {
          print('📄 PAGINATION: No more items found, stopping at page $currentPage');
          break;
        }
        
        allItems.addAll(pageItems);
        
        // If we got less than pageSize items, we've reached the end
        if (pageItems.length < pageSize) {
          print('📄 PAGINATION: Reached end of data at page $currentPage');
          break;
        }
        
        currentPage++;
        
        // Safety check: if we have too many items, stop loading
        if (allItems.length > 1000) {
          print('⚠️ PAGINATION: Safety limit reached (1000 items), stopping');
          break;
        }
      }
      
      print('✅ PAGINATION: Loaded ${allItems.length} total items across ${currentPage - 1} pages');
      return allItems;
      
    } catch (e) {
      print('❌ PAGINATION: Error loading paginated data: $e');
      // Return what we have so far
      return allItems;
    }
  }

  /// Get lightweight summary data (for dashboard/overview)
  Future<List<T>> getSummaryData<T>({
    required Future<List<T>> Function(int page, int limit, List<String> excludeFields) apiCall,
    List<String> excludeFields = const [],
  }) async {
    print('📊 SUMMARY: Loading lightweight summary data');
    return await apiCall(1, 10, excludeFields);  // Only first 10 items for summary
  }

  /// Dispose of resources
  void dispose() {
    _httpClient.dispose();
  }
}