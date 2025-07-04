import '../utils/html_decoder.dart';

class GymOwner {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? gymName;
  final String? gymAddress;
  final String? gymDescription;
  final DateTime? gymEstablishedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  GymOwner({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.gymName,
    this.gymAddress,
    this.gymDescription,
    this.gymEstablishedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GymOwner.fromJson(Map<String, dynamic> json) {
    return GymOwner(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      phoneNumber: json['phone_number'],
      gymName: json['gym_name'],
      gymAddress: json['gym_address'],
      gymDescription: json['gym_description'],
      gymEstablishedDate: json['gym_established_date'] != null
          ? DateTime.parse(json['gym_established_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'gym_name': gymName,
      'gym_address': gymAddress,
      'gym_description': gymDescription,
      'gym_established_date': gymEstablishedDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';
  
  String get displayName {
    final decodedName = HtmlDecoder.decodeGymName(gymName);
    return decodedName.isNotEmpty ? decodedName : fullName;
  }
  
  String get decodedGymName => HtmlDecoder.decodeGymName(gymName);
  
  String get decodedGymDescription => HtmlDecoder.decodeText(gymDescription);
}