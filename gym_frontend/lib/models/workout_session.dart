import 'member.dart';
import 'trainer.dart';

class WorkoutSession {
  final int? id;
  final Member? member;
  final Trainer? trainer;
  final DateTime date;
  final int durationMinutes;
  final String notes;
  final bool completed;

  WorkoutSession({
    this.id,
    this.member,
    this.trainer,
    required this.date,
    required this.durationMinutes,
    this.notes = '',
    this.completed = false,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'],
      member: json['member'] != null ? Member.fromJson(json['member']) : null,
      trainer: json['trainer'] != null ? Trainer.fromJson(json['trainer']) : null,
      date: DateTime.parse(json['date']),
      durationMinutes: json['duration_minutes'],
      notes: json['notes'] ?? '',
      completed: json['completed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member': member?.toJson(),
      'trainer': trainer?.toJson(),
      'date': date.toIso8601String(),
      'duration_minutes': durationMinutes,
      'notes': notes,
      'completed': completed,
    };
  }

  String get statusText => completed ? 'Completed' : 'Upcoming';
  String get memberName => member?.fullName ?? 'Unknown Member';
  String get trainerName => trainer?.fullName ?? 'No Trainer Assigned';
}