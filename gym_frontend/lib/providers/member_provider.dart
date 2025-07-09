import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/member.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_handler.dart';
import '../services/gym_data_service.dart';
import '../security/security_config.dart';

class MemberProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  
  List<Member> _members = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastFetchTime;
  
  // Cache duration - 5 minutes
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<Member> get members => _members;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchMembers({bool forceRefresh = false}) async {
    // Check cache first
    if (!forceRefresh && _lastFetchTime != null && _members.isNotEmpty) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _cacheDuration) {
        return; // Use cached data
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _members = await _apiService.getMembers();
      _lastFetchTime = DateTime.now();
      
      // Don't create mock data - use real backend data only
    } catch (e) {
      print('💥 MemberProvider ERROR: $e');
      
      // Handle network errors with user-friendly messages
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      
      // Only use mock data if backend is completely unreachable (network error)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed')) {
        print('🔌 MEMBERS: Backend unreachable, using mock data');
        _createMockMembers();
      } else {
        print('🔌 MEMBERS: Backend reachable but returned error - no mock data');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
      print('🏋️ MemberProvider: fetchMembers() completed. Loading: $_isLoading, Error: $_errorMessage');
    }
  }

  Future<bool> createMember({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String gender,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String emergencyContactRelation,
    required String address,
    required String membershipType,
    required DateTime joinDate,
    required int subscriptionPlanId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if email already exists
      final existingMembers = _members.where((m) => m.user?.email?.toLowerCase() == email.toLowerCase());
      if (existingMembers.isNotEmpty) {
        final existingMember = existingMembers.first;
        _errorMessage = 'A member with this email already exists: ${existingMember.fullName}';
        print('❌ CREATE MEMBER ERROR: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final headers = await _authService.getAuthHeaders();
      
      // Calculate subscription end date based on plan duration
      // This would typically come from the subscription plan
      final endDate = DateTime(
        joinDate.year,
        joinDate.month + 1, // Default to 1 month, should be dynamic
        joinDate.day,
      );

      final response = await http.post(
        Uri.parse('${SecurityConfig.apiUrl}/members/'),
        headers: headers,
        body: jsonEncode({
          'user': {
            'first_name': firstName,
            'last_name': lastName,
            'email': email,
            'username': email, // Django requires username
          },
          'phone': phoneNumber, // Match Django model field name
          'date_of_birth': dateOfBirth.toIso8601String().split('T')[0], // Date only
          'gender': gender.toLowerCase(), // Add gender field
          'address': address, // Add required address field
          'emergency_contact_name': emergencyContactName,
          'emergency_contact_phone': emergencyContactPhone,
          'emergency_contact_relation': emergencyContactRelation, // Add missing relation field
          'membership_type': membershipType.toLowerCase(), // Ensure lowercase
          'membership_expiry': endDate.toIso8601String().split('T')[0], // Date only
        }),
      );

      print('🏋️ CREATE MEMBER - Status: ${response.statusCode}');
      print('🏋️ CREATE MEMBER - Response: ${response.body}');
      
      if (response.statusCode == 201) {
        final newMember = Member.fromJson(jsonDecode(response.body));
        _members.insert(0, newMember);
        _isLoading = false;
        notifyListeners();
        print('✅ Member created successfully: ${newMember.fullName}');
        return true;
      } else {
        // Parse error message from response
        String errorMsg = 'Failed to create member';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is List && errorData.isNotEmpty) {
            // Handle ValidationError messages that come as a list
            errorMsg = errorData[0].toString().replaceAll('ErrorDetail(string=\'', '').replaceAll('\', code=\'invalid\')', '');
          } else if (errorData is Map && errorData.containsKey('non_field_errors')) {
            errorMsg = errorData['non_field_errors'][0];
          } else if (errorData is Map) {
            // Extract field-specific errors
            final errors = <String>[];
            errorData.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errors.add('$key: ${value[0]}');
              }
            });
            if (errors.isNotEmpty) {
              errorMsg = errors.join(', ');
            }
          }
        } catch (e) {
          errorMsg = 'Server error: ${response.statusCode}';
        }
        
        _errorMessage = errorMsg;
        print('❌ CREATE MEMBER ERROR: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> addMember(Member member) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newMember = await _apiService.createMember(member);
      _members.add(newMember);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Clear all member data and reset for new gym context
  void clearAllData() {
    print('🧹 MEMBERS: Clearing all member data for new gym context');
    _members.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Force refresh member data for current gym
  Future<void> forceRefresh() async {
    print('🔄 MEMBERS: Force refreshing member data');
    clearAllData();
    await fetchMembers();
  }

  Future<bool> updateMemberStatus(int memberId, bool isActive) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.patch(
        Uri.parse('${SecurityConfig.apiUrl}/members/$memberId/'),
        headers: headers,
        body: jsonEncode({
          'is_active': isActive,
        }),
      );

      print('🔄 UPDATE MEMBER STATUS - Status: ${response.statusCode}');
      print('🔄 UPDATE MEMBER STATUS - Response: ${response.body}');

      if (response.statusCode == 200) {
        final updatedMember = Member.fromJson(jsonDecode(response.body));
        final index = _members.indexWhere((m) => m.id == memberId);
        if (index != -1) {
          _members[index] = updatedMember;
        }
        _isLoading = false;
        notifyListeners();
        print('✅ Member status updated successfully');
        return true;
      } else {
        _errorMessage = 'Failed to update member status: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  List<Member> get activeMembers => _members.where((m) => m.isActive).toList();
  
  int get totalMembers => _members.length;
  int get activeMembersCount => activeMembers.length;
  
  void _createMockMembers() {
    final gymDataService = GymDataService();
    final gymName = gymDataService.currentGymName ?? 'Sample Gym';
    
    print('🏋️ MEMBERS: Creating mock member data for gym: $gymName');
    
    final baseMockMembers = [
      Member(
        id: 1,
        user: User(
          id: 1,
          username: 'john.smith@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'john.smith@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'John',
          lastName: 'Smith',
        ),
        phone: '+91 9876543210',
        dateOfBirth: DateTime(1990, 5, 15),
        membershipType: 'premium',
        joinDate: DateTime(2024, 1, 15),
        membershipExpiry: DateTime(2025, 1, 15),
        isActive: true,
        emergencyContactName: 'Jane Smith',
        emergencyContactPhone: '+91 9876543211',
      ),
      Member(
        id: 2,
        user: User(
          id: 2,
          username: 'sarah.wilson@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'sarah.wilson@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'Sarah',
          lastName: 'Wilson',
        ),
        phone: '+91 9876543220',
        dateOfBirth: DateTime(1985, 8, 22),
        membershipType: 'basic',
        joinDate: DateTime(2024, 3, 10),
        membershipExpiry: DateTime(2025, 3, 10),
        isActive: true,
        emergencyContactName: 'Mike Wilson',
        emergencyContactPhone: '+91 9876543221',
      ),
      Member(
        id: 3,
        user: User(
          id: 3,
          username: 'mike.johnson@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'mike.johnson@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'Mike',
          lastName: 'Johnson',
        ),
        phone: '+91 9876543230',
        dateOfBirth: DateTime(1992, 12, 8),
        membershipType: 'premium',
        joinDate: DateTime(2024, 2, 20),
        membershipExpiry: DateTime(2025, 2, 20),
        isActive: true,
        emergencyContactName: 'Lisa Johnson',
        emergencyContactPhone: '+91 9876543231',
      ),
      Member(
        id: 4,
        user: User(
          id: 4,
          username: 'emma.davis@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'emma.davis@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'Emma',
          lastName: 'Davis',
        ),
        phone: '+91 9876543240',
        dateOfBirth: DateTime(1988, 7, 3),
        membershipType: 'basic',
        joinDate: DateTime(2024, 4, 5),
        membershipExpiry: DateTime(2025, 4, 5),
        isActive: false,
        emergencyContactName: 'Robert Davis',
        emergencyContactPhone: '+91 9876543241',
      ),
      Member(
        id: 5,
        user: User(
          id: 5,
          username: 'alex.brown@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: 'alex.brown@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: 'Alex',
          lastName: 'Brown',
        ),
        phone: '+91 9876543250',
        dateOfBirth: DateTime(1995, 3, 18),
        membershipType: 'premium',
        joinDate: DateTime(2024, 6, 1),
        membershipExpiry: DateTime(2025, 6, 1),
        isActive: true,
        emergencyContactName: 'Taylor Brown',
        emergencyContactPhone: '+91 9876543251',
      ),
    ];
    
    // Use gym-specific data isolation with unique IDs
    final gymSpecificMembers = gymDataService.getGymSpecificMockData<Member>(
      baseMockMembers,
      (member, uniqueId) => Member(
        id: uniqueId, // Each gym gets completely unique ID range
        user: User(
          id: uniqueId + 10000, // User IDs offset to prevent conflicts
          username: '${member.user?.firstName?.toLowerCase()}.${member.user?.lastName?.toLowerCase()}@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          email: '${member.user?.firstName?.toLowerCase()}.${member.user?.lastName?.toLowerCase()}@${gymName.toLowerCase().replaceAll(' ', '')}.com',
          firstName: member.user?.firstName ?? '',
          lastName: member.user?.lastName ?? '',
        ),
        phone: member.phone,
        dateOfBirth: member.dateOfBirth,
        membershipType: member.membershipType,
        joinDate: member.joinDate,
        membershipExpiry: member.membershipExpiry,
        isActive: member.isActive,
        emergencyContactName: member.emergencyContactName,
        emergencyContactPhone: member.emergencyContactPhone,
      ),
    );
    
    _members = gymSpecificMembers;
    gymDataService.logDataAccess('members', gymSpecificMembers.length);
  }
}