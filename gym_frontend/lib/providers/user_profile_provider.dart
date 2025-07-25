import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../security/security_config.dart';
import '../security/secure_http_client.dart';

class UserProfileProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final SecureHttpClient _httpClient = SecureHttpClient();

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
      // Starting profile fetch
      final response = await _httpClient.get('auth/profile/', requireAuth: true);

      // Profile fetch status logged
      // Profile response received

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
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
          // Profile fetched successfully
        } else {
          throw Exception('Failed to fetch profile: ${data['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to fetch profile: ${response.errorMessage ?? 'Unknown error'}');
      }
    } catch (e) {
      // Handle specific error types for better user experience
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _errorMessage = 'Authentication expired. Please login again.';
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        _errorMessage = 'Access denied. Please check your permissions.';
      } else if (e.toString().contains('404') || e.toString().contains('Not Found')) {
        _errorMessage = 'Profile not found. Please contact support.';
      } else if (e.toString().contains('500') || e.toString().contains('Internal Server Error')) {
        _errorMessage = 'Server error. Please try again later.';
      } else if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed') ||
          e.toString().contains('TimeoutException')) {
        _errorMessage = 'Network connection error. Please check your internet connection.';
      } else {
        _errorMessage = 'Failed to load profile. Please try again.';
      }
      
      if (kDebugMode) print('Profile fetch error: $e');
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
      final requestBody = <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'gym_name': gymName,
      };
      
      // Add optional fields only if they have values
      if (phone != null && phone.isNotEmpty) {
        requestBody['phone_number'] = phone;
      }
      if (address != null && address.isNotEmpty) {
        requestBody['gym_address'] = address;
      }
      if (gymDescription != null && gymDescription.isNotEmpty) {
        requestBody['gym_description'] = gymDescription;
      }
      if (gymEstablishedDate != null) {
        requestBody['gym_established_date'] = gymEstablishedDate.toIso8601String().split('T')[0];
      }
      if (subscriptionPlan != null && subscriptionPlan.isNotEmpty) {
        requestBody['subscription_plan'] = subscriptionPlan;
      }
      
      // Note: date_of_birth and gender are not supported by the backend GymOwner model
      // These fields are only available for Members, not GymOwners
      
      print('🔄 UPDATE PROFILE: Sending request body: $requestBody');
      
      final response = await _httpClient.put(
        'auth/profile/update/',
        body: requestBody,
        requireAuth: true,
      );

      print('🔄 UPDATE PROFILE - Status: ${response.statusCode}');
      print('🔄 UPDATE PROFILE - Response: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        // Django returns {success: true, gym_owner: {...}, user: {...}}
        if (data['success'] == true) {
          final gymOwner = data['gym_owner'];
          final user = data['user'];
          
          // Handle profile picture URL - prefer full URL from serializer (same logic as fetchCurrentProfile)
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
          
          // Map Django response to UserProfile
          final profileData = {
            'id': user['id'],
            'first_name': user['first_name'],
            'last_name': user['last_name'],
            'email': user['email'],
            'phone': gymOwner['phone_number'],
            'address': gymOwner['gym_address'],
            'profile_picture': profilePictureUrl,
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
        _errorMessage = 'Failed to update profile: ${response.errorMessage ?? 'Unknown error'}';
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
      print('🔄 UPLOAD PICTURE: Starting upload process...');
      
      // Read image file and convert to base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Get file extension for content type
      final fileName = imageFile.path.split('/').last.toLowerCase();
      String contentType = 'image/jpeg'; // default
      if (fileName.endsWith('.png')) {
        contentType = 'image/png';
      } else if (fileName.endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (fileName.endsWith('.heic') || fileName.endsWith('.heif')) {
        contentType = 'image/heic';
      }
      
      print('🔄 UPLOAD PICTURE: File size: ${imageBytes.length} bytes, Type: $contentType');
      
      // Use SecureHttpClient for the upload
      final response = await _httpClient.post(
        'auth/profile/upload-picture/',
        body: {
          'profile_picture_base64': base64Image,
          'content_type': contentType,
          'filename': fileName,
        },
        requireAuth: true,
      );

      print('🔄 UPLOAD PICTURE - Status: ${response.statusCode}');
      print('🔄 UPLOAD PICTURE - Response: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
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
        _errorMessage = 'Failed to upload profile picture: ${response.errorMessage ?? 'Unknown error'}';
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
      final response = await _httpClient.post(
        'auth/profile/change-password/',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        requireAuth: true,
      );

      print('🔄 CHANGE PASSWORD - Status: ${response.statusCode}');

      if (response.isSuccess) {
        _isLoading = false;
        notifyListeners();
        print('✅ Password changed successfully');
        return true;
      } else {
        _errorMessage = response.errorMessage ?? 'Failed to change password';
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