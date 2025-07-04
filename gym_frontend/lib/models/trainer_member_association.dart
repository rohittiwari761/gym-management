import 'member.dart';
import 'trainer.dart';

class TrainerMemberAssociation {
  final int id;
  final Member member;
  final Trainer trainer;
  final DateTime assignedDate;
  final String? assignedBy;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerMemberAssociation({
    required this.id,
    required this.member,
    required this.trainer,
    required this.assignedDate,
    this.assignedBy,
    required this.isActive,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerMemberAssociation.fromJson(Map<String, dynamic> json) {
    return TrainerMemberAssociation(
      id: json['id'],
      member: Member.fromJson(json['member']),
      trainer: Trainer.fromJson(json['trainer']),
      assignedDate: DateTime.parse(json['assigned_date']),
      assignedBy: json['assigned_by']?['first_name'] != null 
          ? '${json['assigned_by']['first_name']} ${json['assigned_by']['last_name']}'
          : null,
      isActive: json['is_active'] ?? true,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': member.id,
      'trainer_id': trainer.id,
      'assigned_date': assignedDate.toIso8601String(),
      'is_active': isActive,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}