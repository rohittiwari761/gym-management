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
  Future<List<Member>> getMembers() async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'members',
        'method': 'GET',
      });

      final response = await _httpClient.get('members/', requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
        } else {
          throw Exception('Unexpected response format');
        }
        
        SecurityConfig.logSecurityEvent('MEMBERS_LOADED', {
          'count': jsonList.length,
        });
        return jsonList.map((json) => Member.fromJson(json)).toList();
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
        emergencyContactName: InputValidator.sanitizeInput(member.emergencyContactName),
        emergencyContactPhone: InputValidator.sanitizeInput(member.emergencyContactPhone),
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
  Future<List<Trainer>> getTrainers() async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'trainers',
        'method': 'GET',
      });

      final response = await _httpClient.get('trainers/', requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
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

  Future<List<Trainer>> getAvailableTrainers() async {
    try {
      final response = await _httpClient.get('trainers/available/', requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
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
  Future<List<Equipment>> getEquipment() async {
    try {
      final response = await _httpClient.get('equipment/', requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.map((json) => Equipment.fromJson(json)).toList();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load equipment');
      }
    } catch (e) {
      throw Exception('Failed to load equipment. Please try again.');
    }
  }

  Future<List<Equipment>> getWorkingEquipment() async {
    try {
      final response = await _httpClient.get('equipment/working/', requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
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
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'equipment/$equipmentId',
        'method': 'DELETE',
      });

      final response = await _httpClient.delete(
        'equipment/$equipmentId/',
        requireAuth: true,
      );

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('EQUIPMENT_DELETED', {
          'equipment_id': equipmentId,
        });
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // Workout Sessions API
  Future<List<WorkoutSession>> getUpcomingSessions() async {
    try {
      final response = await _httpClient.get('workout-sessions/upcoming/', requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
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

  Future<Map<String, dynamic>> getAttendances({DateTime? date}) async {
    try {
      String endpoint = 'attendance/';
      Map<String, dynamic>? queryParams;

      if (date != null) {
        // Use IST timezone for date formatting
        final dateStr = TimezoneUtils.getAPIDateString(date);
        queryParams = {'date': dateStr};
      }

      final response = await _httpClient.get(endpoint, queryParams: queryParams);

      if (response.isSuccess) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': response.errorMessage ?? 'Failed to fetch attendances'};
      }
    } catch (e) {
      return _handleSecureError('get_attendances', e);
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats() async {
    try {
      final response = await _httpClient.get('attendance/stats/');

      if (response.isSuccess) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'message': response.errorMessage ?? 'Failed to fetch attendance stats'};
      }
    } catch (e) {
      return _handleSecureError('get_attendance_stats', e);
    }
  }

  Future<Map<String, dynamic>> getTodayAttendances() async {
    try {
      SecurityConfig.logSecurityEvent('TODAY_ATTENDANCE_REQUEST', {});

      final response = await _httpClient.get('attendance/today_attendance/');

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('TODAY_ATTENDANCE_SUCCESS', {});
        // Handle the specific format from today_attendance endpoint
        if (response.data != null && response.data is Map<String, dynamic>) {
          final responseData = response.data as Map<String, dynamic>;
          final attendances = responseData['attendances'] as List<dynamic>? ?? [];
          return {'success': true, 'data': attendances};
        }
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

  Future<Map<String, dynamic>> getAttendanceAnalytics() async {
    try {
      SecurityConfig.logSecurityEvent('ATTENDANCE_ANALYTICS_REQUEST', {});

      final response = await _httpClient.get('attendance/attendance_analytics/');

      if (response.isSuccess) {
        SecurityConfig.logSecurityEvent('ATTENDANCE_ANALYTICS_SUCCESS', {});
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
  Future<List<Map<String, dynamic>>> getActiveTrainerMemberAssociations() async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'trainer-member-associations/active',
        'method': 'GET',
      });

      final response = await _httpClient.get('trainer-member-associations/active/', requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
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
  Future<List<Map<String, dynamic>>> getTrainerMembers(int trainerId) async {
    try {
      SecurityConfig.logSecurityEvent('API_REQUEST', {
        'endpoint': 'trainers/$trainerId/members',
        'method': 'GET',
      });

      final response = await _httpClient.get('trainers/$trainerId/members/', requireAuth: true);

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
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

  /// Dispose of resources
  void dispose() {
    _httpClient.dispose();
  }
}