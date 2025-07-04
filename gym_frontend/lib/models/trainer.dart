import 'member.dart';

class Trainer {
  final int? id;
  final User? user;
  final String phone;
  final String specialization;
  final int experienceYears;
  final String certification;
  final double hourlyRate;
  final bool isAvailable;

  Trainer({
    this.id,
    this.user,
    required this.phone,
    required this.specialization,
    required this.experienceYears,
    required this.certification,
    required this.hourlyRate,
    this.isAvailable = true,
  });

  factory Trainer.fromJson(Map<String, dynamic> json) {
    return Trainer(
      id: json['id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      phone: json['phone'],
      specialization: json['specialization'],
      experienceYears: json['experience_years'],
      certification: json['certification'],
      hourlyRate: double.parse(json['hourly_rate'].toString()),
      isAvailable: json['is_available'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user?.toJson(),
      'phone': phone,
      'specialization': specialization,
      'experience_years': experienceYears,
      'certification': certification,
      'hourly_rate': hourlyRate,
      'is_available': isAvailable,
    };
  }

  String get fullName => user?.firstName != null && user?.lastName != null ? '${user!.firstName} ${user!.lastName}' : 'Unknown';
  String get displayName => '$fullName - $specialization';
}