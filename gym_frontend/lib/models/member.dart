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
  final String? memberId;  // Added for backend compatibility
  final int? daysUntilExpiry;  // Added for optimized response

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
    this.memberId,
    this.daysUntilExpiry,
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
      memberId: json['member_id'],
      daysUntilExpiry: json['days_until_expiry'],
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
      'member_id': memberId,
      'days_until_expiry': daysUntilExpiry,
    };
  }

  String get fullName => user?.firstName != null && user?.lastName != null ? '${user!.firstName} ${user!.lastName}' : 'Unknown';
  String get phoneNumber => phone;
}