import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../security/security_config.dart';

class UserProfileProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserProfile? _currentProfile;
  List<UserProfile> _allProfiles = [];
  bool _isLoading = false;
  String? _errorMessage;

  UserProfile? get currentProfile => _currentProfile;
  List<UserProfile> get allProfiles => _allProfiles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchCurrentProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${SecurityConfig.apiUrl}/auth/profile/'),
        headers: headers,
      );

      print('🔄 FETCH PROFILE - Status: ${response.statusCode}');
      print('🔄 FETCH PROFILE - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Django returns {success: true, gym_owner: {...}, user: {...}}
        if (data['success'] == true) {
          final gymOwner = data['gym_owner'];
          final user = data['user'];
          
          // Map Django response to UserProfile
          // Handle profile picture URL - prefer full URL from serializer
          String? profilePictureUrl = gymOwner['profile_picture_url'];
          
          // Fallback to building URL manually if needed
          if (profilePictureUrl == null && gymOwner['profile_picture'] != null) {
            final pictureUrl = gymOwner['profile_picture'].toString();
            if (pictureUrl.startsWith('http')) {
              // Already a full URL
              profilePictureUrl = pictureUrl;
            } else if (pictureUrl.isNotEmpty) {
              // Relative URL, make it absolute
              profilePictureUrl = '${SecurityConfig.apiUrl.replaceAll('/api', '')}$pictureUrl';
            }
          }
          
          final profileData = {
            'id': user['id'],
            'first_name': user['first_name'],
            'last_name': user['last_name'],
            'email': user['email'],
            'phone': gymOwner['phone_number'],
            'address': gymOwner['gym_address'],
            'profile_picture': profilePictureUrl,
            'role': 'admin', // Gym owners are admins
            'date_of_birth': null, // Not in gym owner model
            'gender': null, // Not in gym owner model  
            'is_active': gymOwner['is_active'],
            'created_at': gymOwner['created_at'],
            'updated_at': gymOwner['updated_at'],
            // Add gym-specific fields for management
            'gym_name': gymOwner['gym_name'],
            'gym_description': gymOwner['gym_description'],
            'gym_established_date': gymOwner['gym_established_date'],
            'subscription_plan': gymOwner['subscription_plan'],
          };
          
          _currentProfile = UserProfile.fromJson(profileData);
          print('✅ Successfully fetched current profile: ${_currentProfile?.fullName}');
        } else {
          throw Exception('Failed to fetch profile: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      print('❌ FETCH PROFILE ERROR: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
    String? address,
    DateTime? dateOfBirth,
    String? gender,
    String? gymName,
    String? gymDescription,
    DateTime? gymEstablishedDate,
    String? subscriptionPlan,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.put(
        Uri.parse('${SecurityConfig.apiUrl}/auth/profile/update/'),
        headers: headers,
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'phone_number': phone, // Django expects phone_number
          'gym_address': address, // Django maps address to gym_address
          'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
          'gender': gender,
          'gym_name': gymName,
          'gym_description': gymDescription,
          'gym_established_date': gymEstablishedDate?.toIso8601String().split('T')[0],
          'subscription_plan': subscriptionPlan,
        }),
      );

      print('🔄 UPDATE PROFILE - Status: ${response.statusCode}');
      print('🔄 UPDATE PROFILE - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Django returns {success: true, gym_owner: {...}, user: {...}}
        if (data['success'] == true) {
          final gymOwner = data['gym_owner'];
          final user = data['user'];
          
          // Map Django response to UserProfile
          final profileData = {
            'id': user['id'],
            'first_name': user['first_name'],
            'last_name': user['last_name'],
            'email': user['email'],
            'phone': gymOwner['phone_number'],
            'address': gymOwner['gym_address'],
            'profile_picture': gymOwner['profile_picture'],
            'role': 'admin',
            'date_of_birth': null,
            'gender': null,
            'is_active': gymOwner['is_active'],
            'created_at': gymOwner['created_at'],
            'updated_at': gymOwner['updated_at'],
            'gym_name': gymOwner['gym_name'],
            'gym_description': gymOwner['gym_description'],
            'gym_established_date': gymOwner['gym_established_date'],
            'subscription_plan': gymOwner['subscription_plan'],
          };
          
          _currentProfile = UserProfile.fromJson(profileData);
          _isLoading = false;
          notifyListeners();
          print('✅ Profile updated successfully');
          return true;
        } else {
          _errorMessage = 'Failed to update profile: ${data['error'] ?? 'Unknown error'}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Failed to update profile: ${response.statusCode}';
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

  Future<bool> uploadProfilePicture(File imageFile) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      
      // Remove content-type as multipart will set it automatically
      final uploadHeaders = Map<String, String>.from(headers);
      uploadHeaders.remove('Content-Type');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${SecurityConfig.apiUrl}/auth/profile/upload-picture/'),
      );
      
      request.headers.addAll(uploadHeaders);
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_picture',
          imageFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔄 UPLOAD PICTURE - Status: ${response.statusCode}');
      print('🔄 UPLOAD PICTURE - Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Django returns {success: true, gym_owner: {...}, user: {...}, profile_picture_url: "..."}
        if (data['success'] == true) {
          final gymOwner = data['gym_owner'];
          final user = data['user'];
          final profilePictureUrl = data['profile_picture_url']; // New field from backend
          
          // Map Django response to UserProfile
          final profileData = {
            'id': user['id'],
            'first_name': user['first_name'],
            'last_name': user['last_name'],
            'email': user['email'],
            'phone': gymOwner['phone_number'],
            'address': gymOwner['gym_address'],
            'profile_picture': profilePictureUrl ?? gymOwner['profile_picture'], // Use full URL if available
            'role': 'admin',
            'date_of_birth': null,
            'gender': null,
            'is_active': gymOwner['is_active'],
            'created_at': gymOwner['created_at'],
            'updated_at': gymOwner['updated_at'],
            'gym_name': gymOwner['gym_name'],
            'gym_description': gymOwner['gym_description'],
            'gym_established_date': gymOwner['gym_established_date'],
            'subscription_plan': gymOwner['subscription_plan'],
          };
          
          _currentProfile = UserProfile.fromJson(profileData);
          _isLoading = false;
          notifyListeners();
          print('✅ Profile picture uploaded successfully');
          print('🖼️ New profile picture URL: $profilePictureUrl');
          return true;
        } else {
          _errorMessage = 'Failed to upload profile picture: ${data['error'] ?? 'Unknown error'}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Failed to upload profile picture: ${response.statusCode}';
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

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${SecurityConfig.apiUrl}/auth/profile/change-password/'),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      print('🔄 CHANGE PASSWORD - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        print('✅ Password changed successfully');
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'Failed to change password';
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Clear all user profile data for new gym context
  void clearAllData() {
    print('🧹 USER PROFILE: Clearing all profile data for new gym context');
    _currentProfile = null;
    _allProfiles.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Force refresh profile data for current gym
  Future<void> forceRefresh() async {
    print('🔄 USER PROFILE: Force refreshing profile data');
    clearAllData();
    await fetchCurrentProfile();
  }
}