import '../utils/timezone_utils.dart';

class Attendance {
  final int? id;
  final int memberId;
  final String memberName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final Duration? duration;
  final String status; // 'checked_in', 'checked_out'
  final String? notes;

  Attendance({
    this.id,
    required this.memberId,
    required this.memberName,
    required this.checkInTime,
    this.checkOutTime,
    this.duration,
    required this.status,
    this.notes,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    String memberName = 'Unknown';
    int memberId = 0;
    
    // Extract member ID and name from the response
    if (json['member'] != null) {
      final member = json['member'];
      memberId = member['id'] ?? 0;
      
      // Try to get member name from nested user object
      if (member['user'] != null) {
        final user = member['user'];
        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        if (firstName.isNotEmpty || lastName.isNotEmpty) {
          memberName = '$firstName $lastName'.trim();
        }
      }
      
      // Fallback to member_id if name is still empty
      if (memberName == 'Unknown' && member['member_id'] != null) {
        memberName = member['member_id'];
      }
    } else {
      // Fallback for direct member_id field
      memberId = json['member_id'] ?? 0;
      memberName = json['member_name'] ?? 'Unknown';
    }
    
    return Attendance(
      id: json['id'],
      memberId: memberId,
      memberName: memberName,
      checkInTime: DateTime.parse(json['check_in_time']),
      checkOutTime: json['check_out_time'] != null 
          ? DateTime.parse(json['check_out_time']) 
          : null,
      duration: json['duration'] != null 
          ? Duration(minutes: json['duration']) 
          : null,
      status: json['status'] ?? 'checked_in',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'member_name': memberName,
      'check_in_time': checkInTime.toIso8601String(),
      'check_out_time': checkOutTime?.toIso8601String(),
      'duration': duration?.inMinutes,
      'status': status,
      'notes': notes,
    };
  }

  Duration get sessionDuration {
    if (checkOutTime != null) {
      return checkOutTime!.difference(checkInTime);
    }
    return DateTime.now().difference(checkInTime);
  }

  bool get isCheckedIn => status == 'checked_in' && checkOutTime == null;
  bool get isCheckedOut => status == 'checked_out' && checkOutTime != null;

  String get formattedDuration {
    final duration = sessionDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String get checkInTimeFormatted {
    final istTime = TimezoneUtils.toIST(checkInTime);
    return '${istTime.hour.toString().padLeft(2, '0')}:${istTime.minute.toString().padLeft(2, '0')} IST';
  }

  String get checkOutTimeFormatted {
    if (checkOutTime == null) return '--:--';
    final istTime = TimezoneUtils.toIST(checkOutTime!);
    return '${istTime.hour.toString().padLeft(2, '0')}:${istTime.minute.toString().padLeft(2, '0')} IST';
  }
}

class AttendanceStats {
  final int totalMembers;
  final int presentToday;
  final int absentToday;
  final int totalCheckIns;
  final double averageSessionTime;
  final int peakHourCheckIns;
  final String peakHour;

  AttendanceStats({
    required this.totalMembers,
    required this.presentToday,
    required this.absentToday,
    required this.totalCheckIns,
    required this.averageSessionTime,
    required this.peakHourCheckIns,
    required this.peakHour,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalMembers: json['total_members'] ?? 0,
      presentToday: json['present_today'] ?? 0,
      absentToday: json['absent_today'] ?? 0,
      totalCheckIns: json['total_check_ins'] ?? 0,
      averageSessionTime: (json['average_session_time'] ?? 0.0).toDouble(),
      peakHourCheckIns: json['peak_hour_check_ins'] ?? 0,
      peakHour: json['peak_hour'] ?? '09:00',
    );
  }

  double get attendanceRate {
    if (totalMembers == 0) return 0.0;
    return (presentToday / totalMembers) * 100;
  }
}