import 'package:flutter/foundation.dart';
import '../models/attendance.dart';
import '../models/member.dart';
import '../services/api_service.dart';
import '../utils/timezone_utils.dart';

class AttendanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Attendance> _attendances = [];
  List<Attendance> _todayAttendances = [];
  List<Attendance> _historyAttendances = []; // Dedicated history data
  AttendanceStats? _stats;
  bool _isLoading = false;
  bool _isLoadingHistory = false; // Separate loading for history
  String _errorMessage = '';
  DateTime _selectedDate = TimezoneUtils.todayIST;
  DateTime? _historyDate; // Separate date tracking for history
  List<Member> _members = []; // Cache members for name resolution

  List<Attendance> get attendances => _attendances;
  List<Attendance> get todayAttendances => _todayAttendances;
  List<Attendance> get historyAttendances => _historyAttendances;
  AttendanceStats? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;
  DateTime? get historyDate => _historyDate;

  // Get currently checked-in members
  List<Attendance> get currentlyCheckedIn => 
      _todayAttendances.where((a) => a.isCheckedIn).toList();

  // Get checked-out members for today
  List<Attendance> get checkedOutToday => 
      _todayAttendances.where((a) => a.isCheckedOut).toList();

  Future<void> fetchAttendances({DateTime? date}) async {
    _setLoading(true);
    try {
      final dateForDisplay = date != null ? TimezoneUtils.formatISTDate(date) : 'today';
      // Clear previous data to avoid confusion
      _attendances.clear();
      
      final response = await _apiService.getAttendances(
        date: date, // Don't default to DateTime.now() here
      );
      
      if (response['success'] == true) {
        // Handle both direct array and paginated response formats
        List<dynamic> data;
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response format
          data = responseData['results'] as List<dynamic>;
          // Using paginated response format
        } else if (responseData is List<dynamic>) {
          // Direct array format
          data = responseData;
          // Using direct array response format
        } else {
          throw Exception('Unexpected response format: expected array or paginated object');
        }
        
        _attendances = data.map((item) => Attendance.fromJson(item)).toList();
        
        // Fetched attendance data successfully
        
        // Only fetch today's attendance if no specific date was requested
        if (date == null) {
          final todayResponse = await _apiService.getTodayAttendances();
          if (todayResponse['success'] == true) {
            // Handle both direct array and paginated response formats
            List<dynamic> todayData;
            final todayResponseData = todayResponse['data'];
            
            if (todayResponseData is Map<String, dynamic> && todayResponseData.containsKey('results')) {
              // Paginated response format
              todayData = todayResponseData['results'] as List<dynamic>;
              // Using paginated format for today's data
            } else if (todayResponseData is List<dynamic>) {
              // Direct array format
              todayData = todayResponseData;
              // Using direct array format for today's data
            } else {
              throw Exception('Unexpected today attendance response format: expected array or paginated object');
            }
            
            _todayAttendances = todayData.map((item) => Attendance.fromJson(item)).toList();
            
            // Today's attendance data loaded successfully
          } else {
            // Only fallback to filtering if we're actually fetching today's data
            final today = DateTime.now();
            final todayAttendances = await _apiService.getAttendances(date: today);
            if (todayAttendances['success'] == true) {
              // Handle both direct array and paginated response formats
              List<dynamic> fallbackData;
              final fallbackResponseData = todayAttendances['data'];
              
              if (fallbackResponseData is Map<String, dynamic> && fallbackResponseData.containsKey('results')) {
                // Paginated response format
                fallbackData = fallbackResponseData['results'] as List<dynamic>;
                // Using paginated format for fallback data
              } else if (fallbackResponseData is List<dynamic>) {
                // Direct array format
                fallbackData = fallbackResponseData;
                // Using direct array format for fallback data
              } else {
                throw Exception('Unexpected fallback attendance response format: expected array or paginated object');
              }
              
              _todayAttendances = fallbackData.map((item) => Attendance.fromJson(item)).toList();
            } else {
              _todayAttendances = [];
            }
          }
        } else {
          // When fetching a specific historical date, don't mix with today's data
          // Fetching historical date, today's attendance not affected
        }
        
        _errorMessage = '';
        // Attendance data loaded successfully
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch attendances';
        if (kDebugMode) {
          print('ATTENDANCE ERROR: $_errorMessage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ATTENDANCE ERROR: $e');
        print('ATTENDANCE ERROR TYPE: ${e.runtimeType}');
      }
      
      // Handle JSON parsing errors specifically
      if (e.toString().contains('FormatException') || 
          e.toString().contains('type') ||
          e.toString().contains('Unexpected response format')) {
        _errorMessage = 'Server returned invalid data format. Please try again.';
        if (kDebugMode) {
          print('ATTENDANCE: JSON parsing error detected');
        }
      } else {
        _errorMessage = 'Error fetching attendances: $e';
      }
      
      // Only use mock data if backend is completely unreachable (network error)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed')) {
        if (kDebugMode) {
          print('ATTENDANCE: Backend unreachable, using minimal mock data');
        }
        _createMockAttendances();
      } else {
        if (kDebugMode) {
          print('ATTENDANCE: Backend reachable but returned error - no mock data');
        }
        // Set empty data instead of mock data when backend is reachable
        _attendances = [];
        _todayAttendances = [];
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Fetch today's attendance specifically
  Future<void> fetchTodaysAttendance() async {
    try {
      // Fetching today's attendance
      
      final todayResponse = await _apiService.getTodayAttendances();
      if (todayResponse['success'] == true) {
        // Handle both direct array and paginated response formats
        List<dynamic> todayData;
        final todayResponseData = todayResponse['data'];
        
        if (todayResponseData is Map<String, dynamic> && todayResponseData.containsKey('results')) {
          // Paginated response format
          todayData = todayResponseData['results'] as List<dynamic>;
          // Using paginated format
        } else if (todayResponseData is List<dynamic>) {
          // Direct array format
          todayData = todayResponseData;
          // Using direct array format
        } else {
          throw Exception('Unexpected fetch today response format: expected array or paginated object');
        }
        
        _todayAttendances = todayData.map((item) => Attendance.fromJson(item)).toList();
        
        // Fix member names using cache
        _fixTodayAttendanceNames();
        
        // Today's attendance data loaded
        _syncHistoryAfterTodayRefresh(); // Sync with history tab if needed
        notifyListeners();
      } else {
        // Fallback to API call with today's date in IST
        final today = TimezoneUtils.todayIST;
        final todayAttendances = await _apiService.getAttendances(date: today);
        if (todayAttendances['success'] == true) {
          // Handle both direct array and paginated response formats
          List<dynamic> fallbackTodayData;
          final fallbackTodayResponseData = todayAttendances['data'];
          
          if (fallbackTodayResponseData is Map<String, dynamic> && fallbackTodayResponseData.containsKey('results')) {
            // Paginated response format
            fallbackTodayData = fallbackTodayResponseData['results'] as List<dynamic>;
            // Using paginated format for fallback
          } else if (fallbackTodayResponseData is List<dynamic>) {
            // Direct array format
            fallbackTodayData = fallbackTodayResponseData;
            // Using direct array format for fallback
          } else {
            throw Exception('Unexpected fallback today response format: expected array or paginated object');
          }
          
          _todayAttendances = fallbackTodayData.map((item) => Attendance.fromJson(item)).toList();
          _fixTodayAttendanceNames();
          _syncHistoryAfterTodayRefresh(); // Sync with history tab if needed
          notifyListeners();
        } else {
          if (kDebugMode) {
            print('ATTENDANCE: Failed to fetch today\'s attendance');
          }
          _todayAttendances = [];
          _syncHistoryAfterTodayRefresh(); // Sync with history tab if needed
          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ATTENDANCE: Error fetching today\'s attendance: $e');
      }
      _todayAttendances = [];
      _syncHistoryAfterTodayRefresh(); // Sync with history tab if needed
      notifyListeners();
    }
  }

  Future<void> fetchStats() async {
    try {
      // Fetching attendance analytics
      
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
        // Analytics loaded successfully
      } else {
        if (kDebugMode) {
          print('ATTENDANCE ANALYTICS ERROR: ${response['message']}');
        }
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
      if (kDebugMode) {
        print('ATTENDANCE ANALYTICS ERROR: $e');
      }
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
      // Checking in member
      
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
          
          // CRITICAL FIX: Also update history if today's date is selected in history tab
          if (_historyDate != null && TimezoneUtils.isToday(_historyDate!)) {
            _historyAttendances.add(newAttendance);
          }
          // First check-in of day recorded
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
            
            // CRITICAL FIX: Also update history if today's date is selected
            if (_historyDate != null && TimezoneUtils.isToday(_historyDate!)) {
              final historyIndex = _historyAttendances.indexWhere((a) => a.id == existing.id);
              if (historyIndex != -1) {
                _historyAttendances[historyIndex] = updatedAttendance;
              }
            }
          }
          // Subsequent check-in processed
        }
        
        await fetchStats();
        notifyListeners();
        
        // Member checked in successfully
        return true;
      } else {
        // Handle API errors - but still allow multiple check-ins
        String errorMsg = response['message'] ?? 'Check-in failed';
        _errorMessage = errorMsg;
        if (kDebugMode) {
          print('ATTENDANCE CHECK-IN ERROR: $_errorMessage');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ATTENDANCE CHECK-IN ERROR: $e');
      }
      
      // Network error - allow check-in with local handling
      
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
        
        // CRITICAL FIX: Also update history if today's date is selected in history tab
        if (_historyDate != null && TimezoneUtils.isToday(_historyDate!)) {
          _historyAttendances.add(newAttendance);
        }
        // First check-in of day recorded (offline)
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
          
          // CRITICAL FIX: Also update history if today's date is selected
          if (_historyDate != null && TimezoneUtils.isToday(_historyDate!)) {
            final historyIndex = _historyAttendances.indexWhere((a) => a.id == existing.id);
            if (historyIndex != -1) {
              _historyAttendances[historyIndex] = updatedAttendance;
            }
          }
        }
        // Subsequent check-in handled (offline)
      }
      
      notifyListeners();
      return true;
    }
  }

  Future<bool> checkOut(int memberId, {String? notes}) async {
    try {
      // Checking out member
      
      // Find today's attendance record for this member
      final todayAttendanceIndex = _todayAttendances.indexWhere((a) => 
        a.memberId == memberId &&
        a.checkInTime.day == DateTime.now().day
      );
      
      // If no attendance record for today, but member is trying to check out,
      // we should still allow it (maybe they checked in earlier but record wasn't synced)
      if (todayAttendanceIndex == -1) {
        if (kDebugMode) {
          print('ATTENDANCE: No attendance record found, but allowing checkout');
        }
        // We'll handle this case below in the API call
      } else {
        // Check if member is currently checked in
        final currentAttendance = _todayAttendances[todayAttendanceIndex];
        if (!currentAttendance.isCheckedIn) {
          _errorMessage = 'Member is not currently checked in';
          if (kDebugMode) {
            print('ATTENDANCE: Member $memberId is not currently checked in');
          }
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
        
        // Member checked out successfully
        return true;
      } else {
        // Handle API errors - but be more lenient
        String errorMsg = response['message'] ?? 'Check-out failed';
        _errorMessage = errorMsg;
        if (kDebugMode) {
          print('ATTENDANCE CHECK-OUT ERROR: $_errorMessage');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('ATTENDANCE CHECK-OUT ERROR: $e');
      }
      
      // Network error - handle locally if possible
      
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
        
        // Member checked out successfully (offline)
        return true;
      } else {
        if (kDebugMode) {
          print('ATTENDANCE: No local record to update, but allowing checkout operation');
        }
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
    // Convert to IST date (date only, no time)
    final istDate = TimezoneUtils.toIST(date);
    _selectedDate = DateTime(istDate.year, istDate.month, istDate.day);
    // Selected date updated
    fetchAttendances(date: _selectedDate);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _createMockAttendances() {
    if (kDebugMode) {
      print('ATTENDANCE: Creating minimal mock attendance data (backend unreachable)');
    }
    
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
    
    if (kDebugMode) {
      print('ATTENDANCE: Using minimal offline data - connect to Django backend for real data');
    }
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
    if (kDebugMode) {
      print('ATTENDANCE: Mock stats replaced with empty data - use real Django backend analytics');
    }
  }

  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  /// Clear all attendance data and reset for new gym context
  void clearAllData() {
    // Clearing all attendance data for new gym context
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
    // Force refreshing attendance data
    clearAllData();
    await Future.wait([
      fetchAttendances(),
      fetchTodaysAttendance(),
      fetchStats(),
    ]);
  }

  // Update members cache for name resolution
  void updateMembersCache(List<Member> members) {
    _members = members;
    // Updated members cache
    
    // Fix existing attendance records with proper member names
    _fixAttendanceRecordNames();
    _fixTodayAttendanceNames();
    notifyListeners();
  }

  // Fix today's attendance records with proper member names
  void _fixTodayAttendanceNames() {
    if (_members.isNotEmpty) {
      for (int i = 0; i < _todayAttendances.length; i++) {
        final attendance = _todayAttendances[i];
        if (attendance.memberName.isEmpty || attendance.memberName == 'Unknown Member') {
          final member = _members.firstWhere(
            (m) => m.id == attendance.memberId,
            orElse: () => Member(
              id: 0,
              user: User(
                id: 0, 
                username: 'unknown', 
                email: 'unknown@example.com', 
                firstName: 'Unknown', 
                lastName: 'Member'
              ),
              phone: '',
              dateOfBirth: DateTime.now(),
              membershipType: 'Basic',
              membershipExpiry: DateTime.now(),
              isActive: true,
              emergencyContactName: '',
              emergencyContactPhone: '',
            ),
          );
          
          if (member.id != 0) {
            _todayAttendances[i] = Attendance(
              id: attendance.id,
              memberId: attendance.memberId,
              memberName: member.fullName,
              checkInTime: attendance.checkInTime,
              checkOutTime: attendance.checkOutTime,
              status: attendance.status,
              notes: attendance.notes,
            );
            if (kDebugMode) {
              print('ATTENDANCE: Fixed today\'s attendance name for member ${attendance.memberId}: ${member.fullName}');
            }
          }
        }
      }
    }
  }

  // Fix existing attendance records with proper member names
  void _fixAttendanceRecordNames() {
    bool updated = false;
    
    // Only fix attendances if we have members cache available
    if (_members.isEmpty) {
      if (kDebugMode) {
        print('ATTENDANCE: No members cache available, skipping name fixes');
      }
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
          if (kDebugMode) {
            print('ATTENDANCE: Fixed name for member ${attendance.memberId}: ${attendance.memberName} → $correctName');
          }
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
      if (kDebugMode) {
        print('ATTENDANCE: Fixed member names in existing attendance records');
      }
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
    // Cleared mock data for member
  }

  // Helper method to clear all mock data
  void clearAllMockData() {
    _todayAttendances.clear();
    _attendances.removeWhere((a) => a.checkInTime.day == DateTime.now().day);
    notifyListeners();
    // Cleared all mock data
  }

  // Force update all attendance records with correct member names
  void forceUpdateMemberNames() {
    if (_members.isEmpty) {
      if (kDebugMode) {
        print('ATTENDANCE: No members cache available for name resolution');
      }
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
      if (kDebugMode) {
        print('ATTENDANCE: Updated member ${attendance.memberId} name to: $correctName');
      }
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
    if (kDebugMode) {
      print('ATTENDANCE: Force updated all member names');
    }
  }

  // Helper method to refresh today's attendance data from server
  Future<void> _refreshTodayAttendances() async {
    try {
      // Refreshing today's attendance data
      
      final todayResponse = await _apiService.getTodayAttendances();
      if (todayResponse['success'] == true) {
        // Handle both direct array and paginated response formats
        List<dynamic> refreshData;
        final refreshResponseData = todayResponse['data'];
        
        if (refreshResponseData is Map<String, dynamic> && refreshResponseData.containsKey('results')) {
          // Paginated response format
          refreshData = refreshResponseData['results'] as List<dynamic>;
          // Using paginated format for refresh
        } else if (refreshResponseData is List<dynamic>) {
          // Direct array format
          refreshData = refreshResponseData;
          // Using direct array format for refresh
        } else {
          throw Exception('Unexpected refresh today response format: expected array or paginated object');
        }
        
        _todayAttendances = refreshData.map((item) => Attendance.fromJson(item)).toList();
        // Today's attendance data refreshed
      } else {
        if (kDebugMode) {
          print('ATTENDANCE: Failed to refresh today\'s data: ${todayResponse['message']}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ATTENDANCE: Error refreshing today\'s data: $e');
      }
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
      _historyAttendances.clear();
      _stats = null;
      _errorMessage = '';
      _historyDate = null;
      _isLoadingHistory = false;

      // All attendance data has been reset locally
      
      // You could also call an API endpoint here to clear server data
      // await _apiService.resetAllAttendance();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('ATTENDANCE: Error resetting data: $e');
      }
      _errorMessage = 'Failed to reset attendance data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch historical attendance data for a specific date
  Future<void> fetchHistoryAttendances(DateTime date) async {
    _isLoadingHistory = true;
    _historyDate = date;
    notifyListeners();

    try {
      final dateStr = TimezoneUtils.formatISTDate(date);
      // Fetching attendance history and clearing previous data
      
      // Clear previous history data to avoid confusion
      _historyAttendances.clear();
      
      final response = await _apiService.getAttendances(date: date);
      
      if (response['success'] == true) {
        // Handle both direct array and paginated response formats
        List<dynamic> data;
        final responseData = response['data'];
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response format
          data = responseData['results'] as List<dynamic>;
          // Using paginated format for history
        } else if (responseData is List<dynamic>) {
          // Direct array format
          data = responseData;
          // Using direct array format for history
        } else {
          throw Exception('Unexpected history response format: expected array or paginated object');
        }
        
        _historyAttendances = data.map((item) => Attendance.fromJson(item)).toList();
        
        // History attendance data loaded successfully
        
        _errorMessage = '';
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch history attendance';
        _historyAttendances = [];
        if (kDebugMode) {
          print('HISTORY ERROR: $_errorMessage');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('HISTORY ERROR: $e');
      }
      
      // Handle JSON parsing errors specifically
      if (e.toString().contains('FormatException') || 
          e.toString().contains('type') ||
          e.toString().contains('Unexpected response format')) {
        _errorMessage = 'Server returned invalid data format. Please try again.';
        if (kDebugMode) {
          print('HISTORY: JSON parsing error detected');
        }
      } else {
        _errorMessage = 'Error fetching history: $e';
      }
      
      _historyAttendances = [];
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// Set the selected date for history and fetch data
  void setHistoryDate(DateTime date) {
    final istDate = TimezoneUtils.toIST(date);
    final selectedDate = DateTime(istDate.year, istDate.month, istDate.day);
    
    // History date selected
    
    // Only fetch if it's a different date
    if (_historyDate == null || 
        _historyDate!.year != selectedDate.year ||
        _historyDate!.month != selectedDate.month ||
        _historyDate!.day != selectedDate.day) {
      fetchHistoryAttendances(selectedDate);
    }
  }

  /// Clear history data
  void clearHistory() {
    _historyAttendances.clear();
    _historyDate = null;
    _isLoadingHistory = false;
    // History attendance data cleared
    notifyListeners();
  }

  /// Get history stats for the selected date
  Map<String, int> get historyStats {
    if (_historyAttendances.isEmpty) {
      return {
        'total': 0,
        'checkedIn': 0,
        'checkedOut': 0,
      };
    }

    final checkedIn = _historyAttendances.where((a) => a.isCheckedIn).length;
    final checkedOut = _historyAttendances.where((a) => a.isCheckedOut).length;

    return {
      'total': _historyAttendances.length,
      'checkedIn': checkedIn,
      'checkedOut': checkedOut,
    };
  }

  /// Log attendance via QR code scanning
  Future<bool> logAttendanceViaQR({
    required String memberId,
    required String qrData,
    String? gymId,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      // Parse member ID
      final memberIdInt = int.tryParse(memberId);
      if (memberIdInt == null) {
        _errorMessage = 'Invalid member ID format';
        return false;
      }

      // Validate QR data format
      if (!qrData.startsWith('gym_attendance:')) {
        _errorMessage = 'Invalid QR code. Please scan a valid gym attendance QR code.';
        return false;
      }

      // Extract gym info from QR data
      final qrParts = qrData.split(':');
      if (qrParts.length < 3) {
        _errorMessage = 'Invalid QR code format';
        return false;
      }

      final qrGymId = qrParts[1];
      final qrGymName = Uri.decodeComponent(qrParts[2]);

      if (kDebugMode) {
        print('QR_ATTENDANCE: Processing attendance for member $memberIdInt');
        print('QR_ATTENDANCE: Gym ID: $qrGymId, Gym Name: $qrGymName');
      }

      // Check if member is already checked in today
      final alreadyCheckedIn = _todayAttendances.any(
        (a) => a.memberId == memberIdInt && a.isCheckedIn,
      );

      if (alreadyCheckedIn) {
        _errorMessage = 'Member is already checked in today';
        return false;
      }

      // Attempt to check in via API
      try {
        final response = await _apiService.checkIn(
          memberIdInt,
          notes: 'QR Code Check-in at $qrGymName',
        );

        if (response['success'] == true) {
          // Successful API check-in - refresh today's data to ensure sync
          await fetchTodaysAttendance();
          
          if (kDebugMode) {
            print('QR_ATTENDANCE: ✅ Member $memberIdInt checked in successfully via API');
          }
          return true;
        } else {
          // API returned error but we'll handle it locally
          final errorMsg = response['message'] ?? 'API check-in failed';
          if (kDebugMode) {
            print('QR_ATTENDANCE: API check-in failed: $errorMsg');
          }
        }
      } catch (apiError) {
        if (kDebugMode) {
          print('QR_ATTENDANCE: API check-in error: $apiError');
        }
      }

      // Fallback: Local check-in if API fails
      final memberName = resolveMemberName(memberIdInt, fallback: 'Member $memberIdInt');
      
      // Create local attendance record
      final newAttendance = Attendance(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        memberId: memberIdInt,
        memberName: memberName,
        checkInTime: DateTime.now(),
        checkOutTime: null,
        status: 'checked_in',
        notes: 'QR Code Check-in (Local) at $qrGymName',
      );

      // Add to BOTH today's attendances AND main attendances to ensure consistency
      _todayAttendances.add(newAttendance);
      _attendances.add(newAttendance);
      
      // CRITICAL FIX: Also update history if today's date is selected in history tab
      if (_historyDate != null && TimezoneUtils.isToday(_historyDate!)) {
        _historyAttendances.add(newAttendance);
        if (kDebugMode) {
          print('QR_ATTENDANCE: Also added to history attendances for today');
        }
      }
      
      notifyListeners();

      if (kDebugMode) {
        print('QR_ATTENDANCE: ✅ Member $memberIdInt checked in locally via QR');
        print('QR_ATTENDANCE: Added to today\'s list (${_todayAttendances.length} total)');
      }

      return true;

    } catch (e) {
      if (kDebugMode) {
        print('QR_ATTENDANCE: Error: $e');
      }
      _errorMessage = 'Failed to log attendance: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Validate QR code format for attendance
  bool isValidAttendanceQR(String qrData) {
    try {
      if (!qrData.startsWith('gym_attendance:')) {
        return false;
      }

      final parts = qrData.split(':');
      if (parts.length < 3) {
        return false;
      }

      // Check if gym ID is numeric
      final gymId = int.tryParse(parts[1]);
      if (gymId == null) {
        return false;
      }

      // Check if gym name is not empty
      final gymName = Uri.decodeComponent(parts[2]);
      if (gymName.trim().isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extract gym information from QR code
  Map<String, String>? extractGymInfoFromQR(String qrData) {
    try {
      if (!isValidAttendanceQR(qrData)) {
        return null;
      }

      final parts = qrData.split(':');
      final gymId = parts[1];
      final gymName = Uri.decodeComponent(parts[2]);
      final timestamp = parts.length > 3 ? parts[3] : '';

      return {
        'gymId': gymId,
        'gymName': gymName,
        'timestamp': timestamp,
      };
    } catch (e) {
      return null;
    }
  }

  /// Ensure data consistency between today's tab and history tab when today is selected
  void syncTodayWithHistory() {
    if (_historyDate != null && TimezoneUtils.isToday(_historyDate!)) {
      // If history tab is showing today's date, sync with today's data
      _historyAttendances.clear();
      _historyAttendances.addAll(_todayAttendances);
      if (kDebugMode) {
        print('ATTENDANCE_SYNC: Synced history with today\'s data (${_todayAttendances.length} records)');
      }
      notifyListeners();
    }
  }

  /// Call this when today's attendance data is refreshed to maintain sync
  void _syncHistoryAfterTodayRefresh() {
    if (_historyDate != null && TimezoneUtils.isToday(_historyDate!)) {
      // History tab is showing today, so update it with the refreshed today's data
      _historyAttendances.clear();
      _historyAttendances.addAll(_todayAttendances);
      if (kDebugMode) {
        print('ATTENDANCE_SYNC: Updated history tab with refreshed today\'s data');
      }
    }
  }
}