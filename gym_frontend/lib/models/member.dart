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
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
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
  final DateTime dateOfBirth;
  final String membershipType;
  final DateTime? joinDate;
  final DateTime membershipExpiry;
  final bool isActive;
  final String emergencyContactName;
  final String emergencyContactPhone;

  Member({
    this.id,
    this.user,
    required this.phone,
    required this.dateOfBirth,
    required this.membershipType,
    this.joinDate,
    required this.membershipExpiry,
    this.isActive = true,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      phone: json['phone'],
      dateOfBirth: DateTime.parse(json['date_of_birth']),
      membershipType: json['membership_type'],
      joinDate: json['join_date'] != null ? DateTime.parse(json['join_date']) : null,
      membershipExpiry: DateTime.parse(json['membership_expiry']),
      isActive: json['is_active'],
      emergencyContactName: json['emergency_contact_name'],
      emergencyContactPhone: json['emergency_contact_phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'phone': phone,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      'membership_type': membershipType,
      'join_date': joinDate?.toIso8601String().split('T')[0],
      'membership_expiry': membershipExpiry.toIso8601String().split('T')[0],
      'is_active': isActive,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
    };
  }

  String get fullName => user?.firstName != null && user?.lastName != null ? '${user!.firstName} ${user!.lastName}' : 'Unknown';
  String get phoneNumber => phone;
}