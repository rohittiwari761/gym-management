import '../utils/html_decoder.dart';

class UserProfile {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? address;
  final String? profilePicture;
  final String role; // admin, staff, member
  final DateTime? dateOfBirth;
  final String? gender;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Gym management fields
  final String? gymName;
  final String? gymDescription;
  final DateTime? gymEstablishedDate;
  final String? subscriptionPlan;

  UserProfile({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.address,
    this.profilePicture,
    required this.role,
    this.dateOfBirth,
    this.gender,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.gymName,
    this.gymDescription,
    this.gymEstablishedDate,
    this.subscriptionPlan,
  });

  String get fullName => '$firstName $lastName';
  
  String get decodedGymName => HtmlDecoder.decodeGymName(gymName);
  
  String get decodedGymDescription => HtmlDecoder.decodeText(gymDescription);

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      profilePicture: json['profile_picture'],
      role: json['role'] ?? 'member',
      dateOfBirth: json['date_of_birth'] != null 
          ? DateTime.parse(json['date_of_birth']) 
          : null,
      gender: json['gender'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      gymName: json['gym_name'],
      gymDescription: json['gym_description'],
      gymEstablishedDate: json['gym_established_date'] != null
          ? DateTime.parse(json['gym_established_date'])
          : null,
      subscriptionPlan: json['subscription_plan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'profile_picture': profilePicture,
      'role': role,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'gender': gender,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'gym_name': gymName,
      'gym_description': gymDescription,
      'gym_established_date': gymEstablishedDate?.toIso8601String().split('T')[0],
      'subscription_plan': subscriptionPlan,
    };
  }

  UserProfile copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? address,
    String? profilePicture,
    String? role,
    DateTime? dateOfBirth,
    String? gender,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? gymName,
    String? gymDescription,
    DateTime? gymEstablishedDate,
    String? subscriptionPlan,
  }) {
    return UserProfile(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profilePicture: profilePicture ?? this.profilePicture,
      role: role ?? this.role,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gymName: gymName ?? this.gymName,
      gymDescription: gymDescription ?? this.gymDescription,
      gymEstablishedDate: gymEstablishedDate ?? this.gymEstablishedDate,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
    );
  }
}