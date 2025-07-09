import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../providers/member_provider.dart';
import '../models/attendance.dart';
import '../utils/app_theme.dart';
import '../utils/timezone_utils.dart';
import 'qr_scanner_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AttendanceProvider? _attendanceProvider;
  MemberProvider? _memberProvider;
  ScaffoldMessengerState? _scaffoldMessenger;
  
  int? _selectedMemberId;
  String _selectedMemberName = '';
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    _memberProvider = Provider.of<MemberProvider>(context, listen: false);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _attendanceProvider != null && _memberProvider != null) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    _attendanceProvider = null;
    _memberProvider = null;
    _scaffoldMessenger = null;
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // First load members to populate the cache
      await _memberProvider!.fetchMembers();
      
      // Update attendance provider with members cache for name resolution
      if (_memberProvider != null && _attendanceProvider != null) {
        _attendanceProvider!.updateMembersCache(_memberProvider!.members);
      }
      
      // Then load attendance data (which can now use the member names)
      await Future.wait([
        _attendanceProvider!.fetchAttendances(),
        _attendanceProvider!.fetchTodaysAttendance(),
        _attendanceProvider!.fetchStats(),
      ]);
    } catch (e) {
      // Handle error silently
    }
  }

  void _clearMockData() {
    if (_attendanceProvider != null && _scaffoldMessenger != null) {
      // Clear all mock data
      _attendanceProvider!.clearAllMockData();
      
      _scaffoldMessenger!.showSnackBar(
        const SnackBar(
          content: Text('All mock attendance data cleared'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _fixMemberNames() {
    if (_attendanceProvider != null && _scaffoldMessenger != null) {
      // Force update member names
      _attendanceProvider!.forceUpdateMemberNames();
      
      _scaffoldMessenger!.showSnackBar(
        const SnackBar(
          content: Text('Member names updated from database'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'More actions',
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearMockData();
                  break;
                case 'reset':
                  _showResetAllDataDialog();
                  break;
                case 'fix':
                  _fixMemberNames();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Mock Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Reset All Data', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fix',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Fix Member Names'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickActionButton(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordAttendanceTab(),
                _buildTodayAttendanceTab(),
                _buildAttendanceHistoryTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 44,
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const QRScannerScreen(),
              ),
            );
          },
          icon: const Icon(Icons.qr_code_scanner, size: 20),
          label: const Text('QR Scanner', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 2.0,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Record'),
          Tab(text: 'Today'),
          Tab(text: 'History'),
          Tab(text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildRecordAttendanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Check-in Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Theme.of(context).colorScheme.primary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Record Member Attendance',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Member Selection
                  Consumer<MemberProvider>(
                    builder: (context, memberProvider, child) {
                      if (memberProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (memberProvider.members.isEmpty) {
                        return const Text('No members available');
                      }
                      
                      final activeMembers = memberProvider.activeMembers;
                      
                      return DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'Select Member',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        value: _selectedMemberId,
                        items: activeMembers.map((member) {
                          return DropdownMenuItem<int>(
                            value: member.id,
                            child: Text(
                              '${member.fullName} - ${member.phone}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMemberId = value;
                            if (value != null) {
                              final member = activeMembers.firstWhere((m) => m.id == value);
                              _selectedMemberName = member.fullName;
                            }
                          });
                        },
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Notes Field
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note),
                      hintText: 'Add any notes...',
                    ),
                    maxLines: 2,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Check In Button
                  Consumer<AttendanceProvider>(
                    builder: (context, attendanceProvider, child) {
                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _selectedMemberId != null && !attendanceProvider.isLoading
                              ? () => _handleCheckIn()
                              : null,
                          icon: const Icon(Icons.login),
                          label: const Text('Record Attendance'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Member Status Indicator
                  if (_selectedMemberId != null)
                    Consumer<AttendanceProvider>(
                      builder: (context, attendanceProvider, child) {
                        final todayAttendances = attendanceProvider.todayAttendances.where(
                          (a) => a.memberId == _selectedMemberId!
                        ).toList();
                        
                        return Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: todayAttendances.isNotEmpty 
                                ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
                                : Theme.of(context).colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: todayAttendances.isNotEmpty 
                                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                                  : Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                todayAttendances.isNotEmpty ? Icons.check_circle : Icons.pending,
                                color: todayAttendances.isNotEmpty 
                                    ? Theme.of(context).colorScheme.primary 
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todayAttendances.isNotEmpty ? 'Attendance Recorded Today' : 'No Attendance Today',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: todayAttendances.isNotEmpty 
                                            ? Theme.of(context).colorScheme.primary 
                                            : Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (todayAttendances.isNotEmpty)
                                      Text(
                                        'First visit: ${todayAttendances.first.checkInTimeFormatted}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Today's Attendance Summary
          _buildTodaysSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildTodaysSummaryCard() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final todayAttendances = attendanceProvider.todayAttendances;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.today, color: Theme.of(context).colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Today\'s Attendance (${todayAttendances.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                if (todayAttendances.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No attendance recorded today',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                else
                  ...todayAttendances.take(5).map((attendance) => 
                    _buildTodaysAttendanceItem(attendance)
                  ).toList(),
                
                if (todayAttendances.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Text(
                        'and ${todayAttendances.length - 5} more...',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodaysAttendanceItem(Attendance attendance) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              attendance.memberName.isNotEmpty ? attendance.memberName[0].toUpperCase() : 'M',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendance.memberName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Visited at ${attendance.checkInTimeFormatted}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: AppTheme.successGreen,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayAttendanceTab() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        if (attendanceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final todayAttendances = attendanceProvider.todayAttendances;
        
        return Column(
          children: [
            // Today's Stats
            _buildTodayStats(),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search members...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            
            // Attendance List
            Expanded(
              child: todayAttendances.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.access_time, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No attendance records for today',
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _getFilteredAttendances(todayAttendances).length,
                      itemBuilder: (context, index) {
                        final attendance = _getFilteredAttendances(todayAttendances)[index];
                        return _buildAttendanceListItem(attendance);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTodayStats() {
    return Consumer<AttendanceProvider>(
      builder: (context, attendanceProvider, child) {
        final stats = attendanceProvider.stats;
        if (stats == null) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Present Today',
                  '${stats.presentToday}',
                  Icons.check_circle,
                  AppTheme.successGreen,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Total Visits',
                  '${stats.totalCheckIns}',
                  Icons.login,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Attendance Rate',
                  '${stats.attendanceRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppTheme.warningOrange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttendanceHistoryTab() {
    return Column(
      children: [
        // Date Picker
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _selectDate(),
                  icon: const Icon(Icons.calendar_today),
                  label: Consumer<AttendanceProvider>(
                    builder: (context, attendanceProvider, child) {
                      return Text(
                        DateFormat('MMM dd, yyyy').format(attendanceProvider.selectedDate),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  _attendanceProvider?.setSelectedDate(TimezoneUtils.todayIST);
                },
                icon: const Icon(Icons.today),
                label: const Text('Today'),
              ),
            ],
          ),
        ),
        
        // Date Info Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Consumer<AttendanceProvider>(
            builder: (context, attendanceProvider, child) {
              final selectedDate = TimezoneUtils.formatISTDate(attendanceProvider.selectedDate);
              return Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Attendance for $selectedDate (IST)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        
        // Attendance List
        Expanded(
          child: Consumer<AttendanceProvider>(
            builder: (context, attendanceProvider, child) {
              if (attendanceProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final attendances = attendanceProvider.attendances;
              final selectedDate = TimezoneUtils.formatISTDate(attendanceProvider.selectedDate);
              
              // Filter attendances to only show records from the selected date (client-side validation)
              final selectedDateIST = attendanceProvider.selectedDate;
              final filteredAttendances = attendances.where((attendance) {
                final attendanceDateIST = TimezoneUtils.toIST(attendance.checkInTime);
                final isSameDate = attendanceDateIST.year == selectedDateIST.year &&
                                   attendanceDateIST.month == selectedDateIST.month &&
                                   attendanceDateIST.day == selectedDateIST.day;
                return isSameDate;
              }).toList();
              
              if (filteredAttendances.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text(
                        'No attendance records for selected date',
                        style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredAttendances.length,
                itemBuilder: (context, index) {
                  final attendance = filteredAttendances[index];
                  return _buildAttendanceListItem(attendance);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          final stats = attendanceProvider.stats;
          
          if (attendanceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (stats == null) {
            return const Center(
              child: Text('No statistics available'),
            );
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Attendance Statistics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Overview Cards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total Members',
                    '${stats.totalMembers}',
                    Icons.people,
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildStatCard(
                    'Present Today',
                    '${stats.presentToday}',
                    Icons.check_circle,
                    AppTheme.successGreen,
                  ),
                  _buildStatCard(
                    'Absent Today',
                    '${stats.absentToday}',
                    Icons.cancel,
                    AppTheme.errorRed,
                  ),
                  _buildStatCard(
                    'Attendance Rate',
                    '${stats.attendanceRate.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    AppTheme.warningOrange,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Additional Stats
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Session Statistics',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildStatRow(
                        'Average Session Time',
                        '${stats.averageSessionTime.toStringAsFixed(0)} minutes',
                        Icons.timer,
                      ),
                      _buildStatRow(
                        'Peak Hour',
                        '${stats.peakHour} (${stats.peakHourCheckIns} visits)',
                        Icons.access_time,
                      ),
                      _buildStatRow(
                        'Total Visits Today',
                        '${stats.totalCheckIns}',
                        Icons.login,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceListItem(Attendance attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: attendance.isCheckedIn ? Colors.green : Colors.blue,
          child: Text(
            attendance.memberName.isNotEmpty ? attendance.memberName[0].toUpperCase() : 'M',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          attendance.memberName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visit time: ${attendance.checkInTimeFormatted}',
              overflow: TextOverflow.ellipsis,
            ),
            if (attendance.notes != null && attendance.notes!.isNotEmpty)
              Text(
                'Notes: ${attendance.notes}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.green.shade200,
            ),
          ),
          child: Text(
            'Attended',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  List<Attendance> _getFilteredAttendances(List<Attendance> attendances) {
    if (_searchQuery.isEmpty) return attendances;
    
    return attendances.where((attendance) {
      return attendance.memberName.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _attendanceProvider?.selectedDate ?? TimezoneUtils.todayIST,
      firstDate: DateTime(2020),
      lastDate: TimezoneUtils.todayIST, // Don't allow future dates in IST
    );
    
    if (picked != null && _attendanceProvider != null) {
      _attendanceProvider!.setSelectedDate(picked);
    }
  }

  Future<void> _handleCheckIn({int? memberId}) async {
    if (!mounted || _attendanceProvider == null || _scaffoldMessenger == null) return;
    
    final targetMemberId = memberId ?? _selectedMemberId;
    if (targetMemberId == null) return;
    
    // Get member name from MemberProvider instead of attendance records
    String targetMemberName = _selectedMemberName;
    
    if (memberId != null && _memberProvider != null) {
      // Find member by ID in the member provider
      final member = _memberProvider!.members.firstWhere(
        (m) => m.id == memberId,
        orElse: () => throw StateError('Member not found'),
      );
      targetMemberName = member.fullName;
    } else if (targetMemberName.isEmpty && _memberProvider != null) {
      // If selected member name is empty, try to find it from member provider
      try {
        final member = _memberProvider!.members.firstWhere(
          (m) => m.id == targetMemberId,
        );
        targetMemberName = member.fullName;
      } catch (e) {
        targetMemberName = 'Unknown Member';
      }
    }
    
    final success = await _attendanceProvider!.checkIn(
      targetMemberId,
      targetMemberName,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );
    
    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Successfully checked in $targetMemberName'
              : _attendanceProvider!.errorMessage.isNotEmpty
                  ? _attendanceProvider!.errorMessage
                  : 'Failed to check in',
          ),
          backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
        ),
      );
      
      if (success) {
        _notesController.clear();
        setState(() {
          _selectedMemberId = null;
          _selectedMemberName = '';
        });
      }
    }
  }

  void _showResetAllDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reset All Data',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete ALL attendance records from the database. This action cannot be undone.\n\nAre you sure you want to continue?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetAllData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset All Data'),
          ),
        ],
      ),
    );
  }

  void _resetAllData() {
    if (_attendanceProvider != null && _scaffoldMessenger != null) {
      // Clear all attendance data
      _attendanceProvider!.resetAllData();
      
      _scaffoldMessenger!.showSnackBar(
        const SnackBar(
          content: Text('All attendance data has been reset'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

}