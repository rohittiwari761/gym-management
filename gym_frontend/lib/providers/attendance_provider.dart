import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../models/member.dart';
import '../services/api_service.dart';

class AttendanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Attendance> _attendances = [];
  List<Attendance> _todayAttendances = [];
  AttendanceStats? _stats;
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();
  List<Member> _members = []; // Cache members for name resolution

  List<Attendance> get attendances => _attendances;
  List<Attendance> get todayAttendances => _todayAttendances;
  AttendanceStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  // Get currently checked-in members
  List<Attendance> get currentlyCheckedIn => 
      _todayAttendances.where((a) => a.isCheckedIn).toList();

  // Get checked-out members for today
  List<Attendance> get checkedOutToday => 
      _todayAttendances.where((a) => a.isCheckedOut).toList();

  Future<void> fetchAttendances({DateTime? date}) async {
    _setLoading(true);
    try {
      print('📋 ATTENDANCE: Fetching attendances for ${date ?? 'today'}...');
      
      final response = await _apiService.getAttendances(
        date: date ?? DateTime.now(),
      );
      
      if (response['success'] == true) {
        _attendances = (response['data'] as List)
            .map((item) => Attendance.fromJson(item))
            .toList();
        
        // Debug: Check member names after parsing
        for (final attendance in _attendances) {
          print('📋 ATTENDANCE: Parsed attendance - Member ID: ${attendance.memberId}, Name: "${attendance.memberName}"');
        }
        
        // Always fetch today's attendance separately to ensure fresh data
        final todayResponse = await _apiService.getTodayAttendances();
        if (todayResponse['success'] == true) {
          _todayAttendances = (todayResponse['data'] as List)
              .map((item) => Attendance.fromJson(item))
              .toList();
          
          // Debug: Check today's member names after parsing
          for (final attendance in _todayAttendances) {
            print('📋 TODAY ATTENDANCE: Parsed attendance - Member ID: ${attendance.memberId}, Name: "${attendance.memberName}"');
          }
          
          print('✅ ATTENDANCE: Loaded ${_todayAttendances.length} today\'s attendances (${_todayAttendances.where((a) => a.isCheckedIn).length} checked in, ${_todayAttendances.where((a) => a.isCheckedOut).length} checked out)');
        } else {
          // Fallback to filtering from all attendances if today's endpoint fails
          final today = DateTime.now();
          _todayAttendances = _attendances.where((attendance) {
            final checkInDate = attendance.checkInTime;
            return checkInDate.year == today.year &&
                   checkInDate.month == today.month &&
                   checkInDate.day == today.day;
          }).toList();
        }
        
        _errorMessage = '';
        print('✅ ATTENDANCE: Loaded ${_attendances.length} total attendances');
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch attendances';
        print('❌ ATTENDANCE ERROR: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = 'Error fetching attendances: $e';
      print('💥 ATTENDANCE ERROR: $e');
      
      // Only use mock data if backend is completely unreachable (network error)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed')) {
        print('🔌 ATTENDANCE: Backend unreachable, using minimal mock data');
        _createMockAttendances();
      } else {
        print('🔌 ATTENDANCE: Backend reachable but returned error - no mock data');
        // Set empty data instead of mock data when backend is reachable
        _attendances = [];
        _todayAttendances = [];
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchStats() async {
    try {
      print('📊 ATTENDANCE: Fetching real attendance analytics from Django backend...');
      
      final response = await _apiService.getAttendanceAnalytics();
      
      if (response['success'] == true) {
        final data = response['data'];
        _stats = AttendanceStats(
          totalMembers: data['total_active_members'] ?? 0,
          presentToday: data['today']['present'] ?? 0,
          absentToday: data['today']['absent'] ?? 0,
          totalCheckIns: data['week']['total_visits'] ?? 0,
          averageSessionTime: 85.5, // This would need session duration calculation in Django
          peakHourCheckIns: data['today']['still_in_gym'] ?? 0,
          peakHour: '18:00', // This would need peak hour analysis in Django
        );
        print('✅ ATTENDANCE: Loaded real analytics - Present: ${_stats!.presentToday}, Absent: ${_stats!.absentToday}');
      } else {
        print('❌ ATTENDANCE ANALYTICS ERROR: ${response['message']}');
        // Set empty stats instead of mock data
        _stats = AttendanceStats(
          totalMembers: 0,
          presentToday: 0,
          absentToday: 0,
          totalCheckIns: 0,
          averageSessionTime: 0.0,
          peakHourCheckIns: 0,
          peakHour: '00:00',
        );
      }
    } catch (e) {
      print('💥 ATTENDANCE ANALYTICS ERROR: $e');
      // Set empty stats on error instead of mock data
      _stats = AttendanceStats(
        totalMembers: 0,
        presentToday: 0,
        absentToday: 0,
        totalCheckIns: 0,
        averageSessionTime: 0.0,
        peakHourCheckIns: 0,
        peakHour: '00:00',
      );
    }
    notifyListeners();
  }

  Future<bool> checkIn(int memberId, String memberName, {String? notes}) async {
    try {
      print('🔑 ATTENDANCE: Checking in member $memberId ($memberName)...');
      
      // Check if this is the first check-in of the day for attendance record
      final hasFirstCheckInToday = _todayAttendances.any((a) => 
        a.memberId == memberId && 
        a.checkInTime.day == DateTime.now().day &&
        a.checkInTime.month == DateTime.now().month &&
        a.checkInTime.year == DateTime.now().year
      );
      
      // Always allow check-in, but handle attendance record differently
      final response = await _apiService.checkIn(memberId, notes: notes);
      
      if (response['success'] == true) {
        // For first check-in of the day, create/update attendance record
        if (!hasFirstCheckInToday) {
          final resolvedName = resolveMemberName(memberId, fallback: memberName);
          final newAttendance = Attendance(
            id: response['data']['id'],
            memberId: memberId,
            memberName: resolvedName,
            checkInTime: DateTime.now(),
            status: 'checked_in',
            notes: notes,
          );
          
          _todayAttendances.add(newAttendance);
          _attendances.add(newAttendance);
          print('📝 ATTENDANCE: First check-in of day recorded for member $memberId ($resolvedName)');
        } else {
          // Update existing record to show member is currently checked in
          final existingIndex = _todayAttendances.indexWhere((a) => 
            a.memberId == memberId &&
            a.checkInTime.day == DateTime.now().day
          );
          
          if (existingIndex != -1) {
            final existing = _todayAttendances[existingIndex];
            final updatedAttendance = Attendance(
              id: existing.id,
              memberId: existing.memberId,
              memberName: existing.memberName,
              checkInTime: existing.checkInTime, // Keep original first check-in time
              checkOutTime: null, // Clear check-out time since they're checking in again
              status: 'checked_in',
              notes: existing.notes,
            );
            
            _todayAttendances[existingIndex] = updatedAttendance;
            
            // Update main list too
            final mainIndex = _attendances.indexWhere((a) => a.id == existing.id);
            if (mainIndex != -1) {
              _attendances[mainIndex] = updatedAttendance;
            }
          }
          print('🔄 ATTENDANCE: Subsequent check-in for member $memberId (attendance record preserved)');
        }
        
        await fetchStats();
        notifyListeners();
        
        print('✅ ATTENDANCE: Member checked in successfully');
        return true;
      } else {
        // Handle API errors - but still allow multiple check-ins
        String errorMsg = response['message'] ?? 'Check-in failed';
        _errorMessage = errorMsg;
        print('❌ ATTENDANCE CHECK-IN ERROR: $_errorMessage');
        return false;
      }
    } catch (e) {
      print('💥 ATTENDANCE CHECK-IN ERROR: $e');
      
      // Network error - allow check-in with local handling
      print('🔧 ATTENDANCE: API unavailable, handling locally for member $memberId...');
      
      // Check if this is the first check-in of the day
      final hasFirstCheckInToday = _todayAttendances.any((a) => 
        a.memberId == memberId && 
        a.checkInTime.day == DateTime.now().day
      );
      
      if (!hasFirstCheckInToday) {
        // Create first attendance record of the day
        final resolvedName = resolveMemberName(memberId, fallback: memberName);
        final newAttendance = Attendance(
          id: DateTime.now().millisecondsSinceEpoch,
          memberId: memberId,
          memberName: resolvedName,
          checkInTime: DateTime.now(),
          status: 'checked_in',
          notes: notes,
        );
        
        _todayAttendances.add(newAttendance);
        _attendances.add(newAttendance);
        print('📝 ATTENDANCE: First check-in of day recorded (offline) for $resolvedName');
      } else {
        // Just update status for subsequent check-ins
        final existingIndex = _todayAttendances.indexWhere((a) => 
          a.memberId == memberId &&
          a.checkInTime.day == DateTime.now().day
        );
        
        if (existingIndex != -1) {
          final existing = _todayAttendances[existingIndex];
          final updatedAttendance = Attendance(
            id: existing.id,
            memberId: existing.memberId,
            memberName: existing.memberName,
            checkInTime: existing.checkInTime, // Keep original first check-in time
            checkOutTime: null, // Clear check-out time
            status: 'checked_in',
            notes: existing.notes,
          );
          
          _todayAttendances[existingIndex] = updatedAttendance;
        }
        print('🔄 ATTENDANCE: Subsequent check-in handled (offline)');
      }
      
      notifyListeners();
      return true;
    }
  }

  Future<bool> checkOut(int memberId, {String? notes}) async {
    try {
      print('🚪 ATTENDANCE: Checking out member $memberId...');
      
      // Find today's attendance record for this member
      final todayAttendanceIndex = _todayAttendances.indexWhere((a) => 
        a.memberId == memberId &&
        a.checkInTime.day == DateTime.now().day
      );
      
      // If no attendance record for today, but member is trying to check out,
      // we should still allow it (maybe they checked in earlier but record wasn't synced)
      if (todayAttendanceIndex == -1) {
        print('⚠️ ATTENDANCE: No attendance record found, but allowing checkout...');
        // We'll handle this case below in the API call
      } else {
        // Check if member is currently checked in
        final currentAttendance = _todayAttendances[todayAttendanceIndex];
        if (!currentAttendance.isCheckedIn) {
          _errorMessage = 'Member is not currently checked in';
          print('⚠️ ATTENDANCE: Member $memberId is not currently checked in');
          return false;
        }
      }
      
      // Always try the API call for check-out
      final response = await _apiService.checkOut(memberId, notes: notes);
      
      if (response['success'] == true) {
        if (todayAttendanceIndex != -1) {
          // Update existing attendance record
          final currentAttendance = _todayAttendances[todayAttendanceIndex];
          final updatedAttendance = Attendance(
            id: currentAttendance.id,
            memberId: currentAttendance.memberId,
            memberName: currentAttendance.memberName,
            checkInTime: currentAttendance.checkInTime,
            checkOutTime: DateTime.now(),
            status: 'checked_out',
            notes: notes ?? currentAttendance.notes,
          );
          
          _todayAttendances[todayAttendanceIndex] = updatedAttendance;
          
          // Update main list too
          final mainIndex = _attendances.indexWhere((a) => a.id == currentAttendance.id);
          if (mainIndex != -1) {
            _attendances[mainIndex] = updatedAttendance;
          }
        } else {
          // No local record but API succeeded - refresh data to get server state
          await _refreshTodayAttendances();
        }
        
        await fetchStats();
        notifyListeners();
        
        print('✅ ATTENDANCE: Member checked out successfully');
        return true;
      } else {
        // Handle API errors - but be more lenient
        String errorMsg = response['message'] ?? 'Check-out failed';
        _errorMessage = errorMsg;
        print('❌ ATTENDANCE CHECK-OUT ERROR: $_errorMessage');
        return false;
      }
    } catch (e) {
      print('💥 ATTENDANCE CHECK-OUT ERROR: $e');
      
      // Network error - handle locally if possible
      print('🔧 ATTENDANCE: API unavailable, handling checkout locally for member $memberId...');
      
      final attendanceIndex = _todayAttendances.indexWhere(
        (a) => a.memberId == memberId && a.isCheckedIn,
      );
      
      if (attendanceIndex != -1) {
        final attendance = _todayAttendances[attendanceIndex];
        final updatedAttendance = Attendance(
          id: attendance.id,
          memberId: attendance.memberId,
          memberName: attendance.memberName,
          checkInTime: attendance.checkInTime,
          checkOutTime: DateTime.now(),
          status: 'checked_out',
          notes: notes ?? attendance.notes,
        );
        
        _todayAttendances[attendanceIndex] = updatedAttendance;
        notifyListeners();
        
        print('✅ ATTENDANCE: Member checked out successfully (offline)');
        return true;
      } else {
        print('⚠️ ATTENDANCE: No local record to update, but allowing checkout operation');
        return true; // Still return success for user experience
      }
    }
  }

  bool isMemberCheckedIn(int memberId) {
    return _todayAttendances.any(
      (attendance) => attendance.memberId == memberId && attendance.isCheckedIn,
    );
  }

  Attendance? getCurrentSession(int memberId) {
    try {
      return _todayAttendances.firstWhere(
        (attendance) => attendance.memberId == memberId && attendance.isCheckedIn,
      );
    } catch (e) {
      return null;
    }
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchAttendances(date: date);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _createMockAttendances() {
    print('🔧 ATTENDANCE: Creating minimal mock attendance data (backend unreachable)');
    
    // Only create minimal mock data when backend is completely unreachable
    final now = DateTime.now();
    final minimalMockAttendances = [
      Attendance(
        id: 1,
        memberId: 1,
        memberName: 'Sample Member',
        checkInTime: DateTime(now.year, now.month, now.day, 9, 0),
        status: 'checked_in',
        notes: 'Offline mode',
      ),
    ];
    
    _attendances = minimalMockAttendances;
    _todayAttendances = minimalMockAttendances;
    
    print('🚫 ATTENDANCE: Using minimal offline data - connect to Django backend for real data');
  }

  void _createMockStats() {
    // No longer create mock data - set empty stats instead
    _stats = AttendanceStats(
      totalMembers: 0,
      presentToday: 0,
      absentToday: 0,
      totalCheckIns: 0,
      averageSessionTime: 0.0,
      peakHourCheckIns: 0,
      peakHour: '00:00',
    );
    print('🚫 ATTENDANCE: Mock stats replaced with empty data - use real Django backend analytics');
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  /// Clear all attendance data and reset for new gym context
  void clearAllData() {
    print('🧹 ATTENDANCE: Clearing all attendance data for new gym context');
    _attendances.clear();
    _todayAttendances.clear();
    _stats = null;
    _members.clear();
    _errorMessage = '';
    _isLoading = false;
    notifyListeners();
  }
  
  /// Force refresh attendance data for current gym
  Future<void> forceRefresh() async {
    print('🔄 ATTENDANCE: Force refreshing attendance data');
    clearAllData();
    await Future.wait([
      fetchAttendances(),
      fetchStats(),
    ]);
  }

  // Update members cache for name resolution
  void updateMembersCache(List<Member> members) {
    _members = members;
    print('📇 ATTENDANCE: Updated members cache with ${members.length} members');
    
    // Fix existing attendance records with proper member names
    _fixAttendanceRecordNames();
  }

  // Fix existing attendance records with proper member names
  void _fixAttendanceRecordNames() {
    bool updated = false;
    
    // Only fix attendances if we have members cache available
    if (_members.isEmpty) {
      print('📇 ATTENDANCE: No members cache available, skipping name fixes');
      return;
    }
    
    // Fix today's attendances
    for (int i = 0; i < _todayAttendances.length; i++) {
      final attendance = _todayAttendances[i];
      // Only fix names that are clearly broken (Unknown or Member ID patterns)
      if (attendance.memberName == 'Unknown' || attendance.memberName.startsWith('Member ')) {
        final correctName = resolveMemberName(attendance.memberId, fallback: attendance.memberName);
        if (correctName != attendance.memberName && !correctName.startsWith('Member ')) {
          _todayAttendances[i] = Attendance(
            id: attendance.id,
            memberId: attendance.memberId,
            memberName: correctName,
            checkInTime: attendance.checkInTime,
            checkOutTime: attendance.checkOutTime,
            status: attendance.status,
            notes: attendance.notes,
          );
          updated = true;
          print('🔧 ATTENDANCE: Fixed name for member ${attendance.memberId}: ${attendance.memberName} → $correctName');
        }
      }
    }
    
    // Fix all attendances
    for (int i = 0; i < _attendances.length; i++) {
      final attendance = _attendances[i];
      // Only fix names that are clearly broken (Unknown or Member ID patterns)
      if (attendance.memberName == 'Unknown' || attendance.memberName.startsWith('Member ')) {
        final correctName = resolveMemberName(attendance.memberId, fallback: attendance.memberName);
        if (correctName != attendance.memberName && !correctName.startsWith('Member ')) {
          _attendances[i] = Attendance(
            id: attendance.id,
            memberId: attendance.memberId,
            memberName: correctName,
            checkInTime: attendance.checkInTime,
            checkOutTime: attendance.checkOutTime,
            status: attendance.status,
            notes: attendance.notes,
          );
          updated = true;
        }
      }
    }
    
    if (updated) {
      notifyListeners();
      print('✅ ATTENDANCE: Fixed member names in existing attendance records');
    }
  }

  // Helper to resolve member name from ID
  String resolveMemberName(int memberId, {String fallback = ''}) {
    try {
      final member = _members.firstWhere((m) => m.id == memberId);
      return member.fullName;
    } catch (e) {
      // If not found in cache, return fallback or generate a name
      if (fallback.isNotEmpty) {
        return fallback;
      }
      return 'Member $memberId';
    }
  }

  // Helper method to clear mock data for a specific member (useful for testing)
  void clearMemberFromMockData(int memberId) {
    _todayAttendances.removeWhere((a) => a.memberId == memberId);
    _attendances.removeWhere((a) => a.memberId == memberId && a.checkInTime.day == DateTime.now().day);
    notifyListeners();
    print('🧹 ATTENDANCE: Cleared mock data for member $memberId');
  }

  // Helper method to clear all mock data
  void clearAllMockData() {
    _todayAttendances.clear();
    _attendances.removeWhere((a) => a.checkInTime.day == DateTime.now().day);
    notifyListeners();
    print('🧹 ATTENDANCE: Cleared all mock data');
  }

  // Force update all attendance records with correct member names
  void forceUpdateMemberNames() {
    if (_members.isEmpty) {
      print('⚠️ ATTENDANCE: No members cache available for name resolution');
      return;
    }
    
    // Force update all records regardless of current name
    for (int i = 0; i < _todayAttendances.length; i++) {
      final attendance = _todayAttendances[i];
      final correctName = resolveMemberName(attendance.memberId);
      _todayAttendances[i] = Attendance(
        id: attendance.id,
        memberId: attendance.memberId,
        memberName: correctName,
        checkInTime: attendance.checkInTime,
        checkOutTime: attendance.checkOutTime,
        status: attendance.status,
        notes: attendance.notes,
      );
      print('🔄 ATTENDANCE: Updated member ${attendance.memberId} name to: $correctName');
    }
    
    for (int i = 0; i < _attendances.length; i++) {
      final attendance = _attendances[i];
      final correctName = resolveMemberName(attendance.memberId);
      _attendances[i] = Attendance(
        id: attendance.id,
        memberId: attendance.memberId,
        memberName: correctName,
        checkInTime: attendance.checkInTime,
        checkOutTime: attendance.checkOutTime,
        status: attendance.status,
        notes: attendance.notes,
      );
    }
    
    notifyListeners();
    print('✅ ATTENDANCE: Force updated all member names');
  }

  // Helper method to refresh today's attendance data from server
  Future<void> _refreshTodayAttendances() async {
    try {
      print('🔄 ATTENDANCE: Refreshing today\'s attendance data...');
      
      final todayResponse = await _apiService.getTodayAttendances();
      if (todayResponse['success'] == true) {
        _todayAttendances = (todayResponse['data'] as List)
            .map((item) => Attendance.fromJson(item))
            .toList();
        print('✅ ATTENDANCE: Refreshed ${_todayAttendances.length} today\'s attendances (${_todayAttendances.where((a) => a.isCheckedIn).length} checked in, ${_todayAttendances.where((a) => a.isCheckedOut).length} checked out)');
      } else {
        print('⚠️ ATTENDANCE: Failed to refresh today\'s data: ${todayResponse['message']}');
      }
    } catch (e) {
      print('💥 ATTENDANCE: Error refreshing today\'s data: $e');
    }
  }

  // Reset all attendance data
  Future<void> resetAllData() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Clear all local data
      _attendances.clear();
      _todayAttendances.clear();
      _stats = null;
      _errorMessage = '';

      print('🗑️ ATTENDANCE: All attendance data has been reset locally');
      
      // You could also call an API endpoint here to clear server data
      // await _apiService.resetAllAttendance();
      
      notifyListeners();
    } catch (e) {
      print('💥 ATTENDANCE: Error resetting data: $e');
      _errorMessage = 'Failed to reset attendance data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}