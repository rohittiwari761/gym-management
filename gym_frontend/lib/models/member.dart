class User {
  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }

  String get fullName => '$firstName $lastName';
}

class Member {
  final int? id;
  final User? user;
  final String phone;
  final DateTime? dateOfBirth;  // Made optional for list serializer
  final String membershipType;
  final DateTime? joinDate;
  final DateTime membershipExpiry;
  final bool isActive;
  final String? emergencyContactName;  // Made optional for list serializer
  final String? emergencyContactPhone;  // Made optional for list serializer
  final String? emergencyContactRelation;  // Emergency contact relationship
  final String? address;  // Member's home address
  final String? memberId;  // Added for backend compatibility
  final int? daysUntilExpiry;  // Added for optimized response
  
  // New physical attributes
  final double? heightCm;
  final double? weightKg;
  final double? bmi;
  final String? bmiCategory;
  final String? profilePictureUrl;
  final int? age;

  Member({
    this.id,
    this.user,
    required this.phone,
    this.dateOfBirth,  // Made optional
    required this.membershipType,
    this.joinDate,
    required this.membershipExpiry,
    this.isActive = true,
    this.emergencyContactName,  // Made optional
    this.emergencyContactPhone,  // Made optional
    this.emergencyContactRelation,  // Made optional
    this.address,  // Made optional
    this.memberId,
    this.daysUntilExpiry,
    // New fields
    this.heightCm,
    this.weightKg,
    this.bmi,
    this.bmiCategory,
    this.profilePictureUrl,
    this.age,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      phone: json['phone'] ?? '',
      dateOfBirth: json['date_of_birth'] != null ? DateTime.parse(json['date_of_birth']) : null,
      membershipType: json['membership_type'] ?? '',
      joinDate: json['join_date'] != null ? DateTime.parse(json['join_date']) : null,
      membershipExpiry: json['membership_expiry'] != null 
          ? DateTime.parse(json['membership_expiry'])
          : DateTime.now().add(Duration(days: 30)), // Fallback for missing expiry
      isActive: json['is_active'] ?? true,
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
      emergencyContactRelation: json['emergency_contact_relation'],
      address: json['address'],
      memberId: json['member_id'],
      daysUntilExpiry: json['days_until_expiry'],
      // New fields
      heightCm: json['height_cm']?.toDouble(),
      weightKg: json['weight_kg']?.toDouble(),
      bmi: json['bmi']?.toDouble(),
      bmiCategory: json['bmi_category'],
      profilePictureUrl: json['profile_picture_url'],
      age: json['age'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'phone': phone,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'membership_type': membershipType,
      'join_date': joinDate?.toIso8601String().split('T')[0],
      'membership_expiry': membershipExpiry.toIso8601String().split('T')[0],
      'is_active': isActive,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'emergency_contact_relation': emergencyContactRelation,
      'address': address,
      'member_id': memberId,
      'days_until_expiry': daysUntilExpiry,
      // New fields
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'bmi': bmi,
      'bmi_category': bmiCategory,
      'profile_picture_url': profilePictureUrl,
      'age': age,
    };
  }

  String get fullName => user?.firstName != null && user?.lastName != null ? '${user!.firstName} ${user!.lastName}' : 'Unknown';
  String get phoneNumber => phone;
  
  // Helper getters for physical attributes
  String get heightDisplay => heightCm != null ? '${heightCm!.toStringAsFixed(0)} cm' : 'Not provided';
  String get weightDisplay => weightKg != null ? '${weightKg!.toStringAsFixed(1)} kg' : 'Not provided';
  String get bmiDisplay => bmi != null ? '${bmi!.toStringAsFixed(1)}' : 'N/A';
  String get ageDisplay => age != null ? '$age years old' : 'Unknown age';
  
  bool get hasPhysicalData => heightCm != null && weightKg != null;
  bool get hasBmi => bmi != null;
  
  // BMI status color helper
  String get bmiStatusColor {
    if (bmiCategory == null) return 'grey';
    switch (bmiCategory!) {
      case 'Underweight':
        return 'blue';
      case 'Normal weight':
        return 'green';
      case 'Overweight':
        return 'orange';
      case 'Obese':
        return 'red';
      default:
        return 'grey';
    }
  }
}