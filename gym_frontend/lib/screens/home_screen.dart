import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../providers/trainer_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/attendance_provider.dart';
import '../services/data_refresh_service.dart';
import '../services/gym_data_service.dart';
import '../utils/html_decoder.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/web_layout.dart';
import 'members_screen.dart';
import 'trainers_screen.dart';
import 'equipment_screen.dart';
import 'attendance_screen.dart';
import 'subscription_plans_screen.dart';
import 'payments_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'member_qr_screen.dart';
import 'login_screen.dart';
import 'add_member_screen.dart';
import 'qr_scanner_screen.dart';
import 'create_subscription_plan_screen.dart';
import 'create_payment_screen.dart';
import 'debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely get the provider reference during dependency changes
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _authProvider = null;
    super.dispose();
  }

  void _loadData() {
    // Load critical data first (members for dashboard), then load rest in background
    Future.microtask(() async {
      if (!mounted) return;
      
      try {
        // Starting optimized data loading for dashboard
        
        // Load critical summary data first for faster UI response (only first page)
        if (mounted) {
          await context.read<MemberProvider>().fetchMembers(
            loadAll: false,  // Just summary data for dashboard
            limit: 10,       // Only 10 members for dashboard stats
          );
        }
        
        // Load non-critical summary data in parallel for better performance
        if (mounted) {
          final futures = [
            // context.read<TrainerProvider>().fetchTrainers(),  // Update when TrainerProvider is optimized
            context.read<EquipmentProvider>().fetchEquipment(
              loadAll: false,  // Just summary data for dashboard
            ),
            context.read<SubscriptionProvider>().fetchSubscriptionPlans(),
            context.read<PaymentProvider>().fetchRevenueAnalytics(),
          ];
          
          await Future.wait(futures, eagerError: false);
        }
        
        // Optimized dashboard data loading completed
      } catch (e) {
        // Silently handle errors in production
        if (kDebugMode) print('HomeScreen data loading error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebLayoutWrapper(
      currentRoute: '/dashboard',
      pageTitle: 'Dashboard',
      actions: kDebugMode ? [
        FloatingActionButton.extended(
          onPressed: () {
            _showDebugInfo(context);
          },
          label: const Text('Debug'),
          icon: const Icon(Icons.bug_report),
          backgroundColor: Colors.red,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.bug_report, color: Colors.grey),
          tooltip: 'Debug Tools',
          onSelected: (value) async {
            switch (value) {
              case 'reset_all':
                await _resetAllDataForCurrentGym();
                break;
              case 'force_clean':
                await _forceCompleteReset();
                break;
              case 'log_state':
                _logCurrentDataState();
                break;
              case 'test_isolation':
                _testDataIsolation();
                break;
              case 'disable_mock':
                _disableMockData();
                break;
              case 'enable_mock':
                _enableMockData();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'reset_all',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 20),
                  SizedBox(width: 8),
                  Text('Reset Gym Data'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'force_clean',
              child: Row(
                children: [
                  Icon(Icons.cleaning_services, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Force Clean State', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'log_state',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('Log Data State'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'test_isolation',
              child: Row(
                children: [
                  Icon(Icons.security, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Test Data Isolation'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'disable_mock',
              child: Row(
                children: [
                  Icon(Icons.clear_all, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Disable Mock Data'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'enable_mock',
              child: Row(
                children: [
                  Icon(Icons.add_circle, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Enable Mock Data'),
                ],
              ),
            ),
          ],
        ),
      ] : null,
      child: Scaffold(
        // Add floating debug info for mobile platforms
        floatingActionButton: (!kIsWeb && kDebugMode) ? FloatingActionButton.extended(
          onPressed: () {
            _showDebugInfo(context);
          },
          label: const Text('Debug'),
          icon: const Icon(Icons.bug_report),
          backgroundColor: Colors.red,
        ) : null,
        drawer: (!kIsWeb || context.isWebMobile) ? _buildDrawer() : null,
        appBar: (!kIsWeb || context.isWebMobile) ? AppBar(
          title: const Text('Gym Management'),
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            // Debug reset button for testing gym-specific data isolation
            if (kDebugMode)
              PopupMenuButton<String>(
                icon: const Icon(Icons.bug_report, color: Colors.white),
                tooltip: 'Debug Tools',
                onSelected: (value) async {
                  switch (value) {
                    case 'reset_all':
                      await _resetAllDataForCurrentGym();
                      break;
                    case 'force_clean':
                      await _forceCompleteReset();
                      break;
                    case 'log_state':
                      _logCurrentDataState();
                      break;
                    case 'test_isolation':
                      _testDataIsolation();
                      break;
                    case 'disable_mock':
                      _disableMockData();
                      break;
                    case 'enable_mock':
                      _enableMockData();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reset_all',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 20),
                        SizedBox(width: 8),
                        Text('Reset Gym Data'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'force_clean',
                    child: Row(
                      children: [
                        Icon(Icons.cleaning_services, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Force Clean State', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'log_state',
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 20),
                        SizedBox(width: 8),
                        Text('Log Data State'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'test_isolation',
                    child: Row(
                      children: [
                        Icon(Icons.security, size: 20, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Test Data Isolation'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'disable_mock',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 20, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Disable Mock Data'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'enable_mock',
                    child: Row(
                      children: [
                        Icon(Icons.add_circle, size: 20, color: Colors.green),
                        SizedBox(width: 8),
                        Text('Enable Mock Data'),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ) : null,
        body: const DashboardScreen(),
      ),
    );
  }


  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              if (mounted && _authProvider != null) {
                // Use enhanced logout that clears all provider data
                await _authProvider!.logoutWithDataClear(context);
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer<MemberProvider>(
                builder: (context, memberProvider, child) {
                  return Text('Members: ${memberProvider.members.length}');
                },
              ),
              Consumer<TrainerProvider>(
                builder: (context, trainerProvider, child) {
                  return Text('Trainers: ${trainerProvider.trainers.length}');
                },
              ),
              Consumer<EquipmentProvider>(
                builder: (context, equipmentProvider, child) {
                  return Text('Equipment: ${equipmentProvider.equipment.length}');
                },
              ),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Text('Current User: ${authProvider.currentUser?.email ?? 'Not logged in'}');
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfileManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  void _showSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header with gradient background
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade600, Colors.blue.shade800],
              ),
            ),
            child: Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                final userName = user != null 
                    ? '${user.firstName} ${user.lastName}'
                    : 'Loading...';
                final gymName = user?.gymName ?? 'Gym Management';
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.fitness_center,
                        size: 35,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      gymName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    // Stay on dashboard (current screen)
                  },
                  isSelected: true, // Dashboard is always selected since it's the home
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Members',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const MembersScreen(),
                    ));
                  },
                  isSelected: false,
                ),
                _buildDrawerItem(
                  icon: Icons.fitness_center,
                  title: 'Trainers',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const TrainersScreen(),
                    ));
                  },
                  isSelected: false,
                ),
                _buildDrawerItem(
                  icon: Icons.sports_gymnastics,
                  title: 'Equipment',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const EquipmentScreen(),
                    ));
                  },
                  isSelected: false,
                ),
                _buildDrawerItem(
                  icon: Icons.access_time,
                  title: 'Attendance',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const AttendanceScreen(),
                    ));
                  },
                  isSelected: false,
                ),
                _buildDrawerItem(
                  icon: Icons.card_membership,
                  title: 'Plans',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const SubscriptionPlansScreen(),
                    ));
                  },
                  isSelected: false,
                ),
                _buildDrawerItem(
                  icon: Icons.payment,
                  title: 'Payments',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const PaymentsScreen(),
                    ));
                  },
                  isSelected: false,
                ),
                const Divider(height: 30),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    _showProfileManagement();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    _showSettings();
                  },
                ),
                if (kDebugMode)
                  _buildDrawerItem(
                    icon: Icons.bug_report,
                    title: 'Debug & Connectivity',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const DebugScreen(),
                      ));
                    },
                    textColor: Colors.red,
                  ),
              ],
            ),
          ),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () => _showLogoutDialog(context),
                  textColor: Colors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? textColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.blue.withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected 
              ? Colors.blue 
              : textColor ?? Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected 
                ? Colors.blue 
                : textColor ?? Colors.grey[800],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Reset all data for the current gym (debug method)
  Future<void> _resetAllDataForCurrentGym() async {
    try {
      print('🔄 DEBUG: Starting gym data reset...');
      
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Resetting gym data...'),
            ],
          ),
        ),
      );
      
      // Get all providers
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final trainerProvider = Provider.of<TrainerProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
      
      // Refresh all data for current gym
      await DataRefreshService.refreshAllDataForNewGym(
        memberProvider: memberProvider,
        attendanceProvider: attendanceProvider,
        trainerProvider: trainerProvider,
        equipmentProvider: equipmentProvider,
        paymentProvider: paymentProvider,
        subscriptionProvider: subscriptionProvider,
        userProfileProvider: userProfileProvider,
      );
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Gym data reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      print('💥 DEBUG: Error resetting gym data: $e');
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to reset gym data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Force complete reset and clean state (debug method)
  Future<void> _forceCompleteReset() async {
    try {
      print('🔥 DEBUG: Starting complete reset...');
      
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Force Complete Reset'),
            ],
          ),
          content: const Text(
            'This will completely reset ALL data and require you to log in again. This action cannot be undone.\n\nAre you sure?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reset All', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Performing complete reset...'),
            ],
          ),
        ),
      );
      
      // Force complete reset
      await _authProvider?.forceCleanState();
      
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
        
        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('🎯 Complete reset finished! Please log in again.'),
            backgroundColor: Colors.blue,
          ),
        );
      }
      
    } catch (e) {
      print('💥 DEBUG: Error in complete reset: $e');
      
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to perform complete reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  /// Log current data state (debug method)
  void _logCurrentDataState() {
    try {
      print('📊 DEBUG: Logging current data state...');
      
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final trainerProvider = Provider.of<TrainerProvider>(context, listen: false);
      final equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      
      // Log gym data service state
      print('🏋️ Gym Data Service:');
      print('  - Initialized: ${GymDataService().isInitialized}');
      print('  - Current Gym ID: ${GymDataService().currentGymOwnerId}');
      print('  - Current Gym Name: ${GymDataService().currentGymName}');
      
      // Log auth state
      print('🔐 Auth State:');
      print('  - Logged In: ${_authProvider?.isLoggedIn}');
      print('  - Current User: ${_authProvider?.currentUser?.displayName}');
      
      // Log provider data
      DataRefreshService.logCurrentDataState(
        memberProvider: memberProvider,
        attendanceProvider: attendanceProvider,
        trainerProvider: trainerProvider,
        equipmentProvider: equipmentProvider,
        paymentProvider: paymentProvider,
      );
      
      // Show info dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Data State Logged'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gym: ${HtmlDecoder.decodeGymName(GymDataService().currentGymName) ?? 'Not set'}'),
              Text('Gym ID: ${GymDataService().currentGymOwnerId ?? 'Not set'}'),
              const SizedBox(height: 8),
              Text('Members: ${memberProvider.members.length}'),
              Text('Trainers: ${trainerProvider.trainers.length}'),
              Text('Equipment: ${equipmentProvider.equipment.length}'),
              Text('Payments: ${paymentProvider.payments.length}'),
              const SizedBox(height: 8),
              const Text('Check console for detailed logs.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      print('💥 DEBUG: Error logging data state: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to log data state: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Test data isolation by showing detailed member data (debug method)
  void _testDataIsolation() {
    try {
      print('🧪 DEBUG: Testing data isolation...');
      
      final memberProvider = Provider.of<MemberProvider>(context, listen: false);
      final gymOwnerId = GymDataService().currentGymOwnerId;
      final gymName = HtmlDecoder.decodeGymName(GymDataService().currentGymName);
      
      print('🏋️ ISOLATION TEST: Current Gym Details:');
      print('  - Gym Owner ID: $gymOwnerId');
      print('  - Gym Name: $gymName');
      print('  - Expected ID Range: ${gymOwnerId! * 1000}-${(gymOwnerId * 1000) + 99}');
      
      print('👥 ISOLATION TEST: Member Data:');
      for (final member in memberProvider.members) {
        print('  - Member ${member.id}: ${member.fullName} (${member.user?.email})');
      }
      
      // Show detailed isolation test dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🧪 Data Isolation Test'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gym: $gymName', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Gym Owner ID: $gymOwnerId'),
                Text('Expected ID Range: ${gymOwnerId * 1000}-${(gymOwnerId * 1000) + 99}'),
                const SizedBox(height: 16),
                const Text('Member Data:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...memberProvider.members.map((member) => Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${member.id} - ${member.fullName}'),
                      Text('Email: ${member.user?.email}', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 16),
                Text(
                  'IDs should be in range ${gymOwnerId * 1000}-${(gymOwnerId * 1000) + 99} for proper isolation!',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetAllDataForCurrentGym();
              },
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      print('💥 DEBUG: Error testing data isolation: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to test data isolation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Disable mock data generation
  void _disableMockData() {
    try {
      GymDataService().disableMockDataGeneration();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚫 Mock data generation disabled - next data refresh will be empty'),
          backgroundColor: Colors.orange,
        ),
      );
      
    } catch (e) {
      print('💥 DEBUG: Error disabling mock data: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to disable mock data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Enable mock data generation  
  void _enableMockData() {
    try {
      GymDataService().enableMockDataGeneration();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mock data generation enabled - next data refresh will include demo data'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('💥 DEBUG: Error enabling mock data: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to enable mock data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _refreshData(BuildContext context) async {
    print('🔄 DASHBOARD: Starting optimized refresh...');
    
    // Show loading indicator
    try {
      // Refresh providers data with optimized loading (summary data only for dashboard)
      await Future.wait([
        context.read<MemberProvider>().fetchMembers(
          forceRefresh: true,
          loadAll: false,  // Just summary for dashboard
          limit: 10,       // Only 10 items for dashboard stats
        ),
        // context.read<TrainerProvider>().fetchTrainers(), // Update when optimized
        context.read<EquipmentProvider>().fetchEquipment(
          loadAll: false,  // Just summary for dashboard
        ),
        context.read<SubscriptionProvider>().fetchSubscriptionPlans(),
        context.read<PaymentProvider>().fetchRevenueAnalytics(),
        context.read<AttendanceProvider>().fetchAttendances(),
      ]);
      
      print('✅ DASHBOARD: Optimized refresh completed successfully');
      
      // Show success feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📊 Dashboard refreshed successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('💥 DASHBOARD: Refresh failed: $e');
      
      // Show error feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Refresh failed: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refreshData(context),
      color: Colors.blue,
      backgroundColor: Colors.white,
      strokeWidth: 2.0,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works even when content is short
        padding: context.isWebDesktop ? EdgeInsets.zero : const EdgeInsets.all(16.0),
        child: context.isWebDesktop 
            ? _buildWebDashboard(context)
            : _buildMobileDashboard(context),
      ),
    );
  }

  Widget _buildWebDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section for Web
        _buildWebWelcomeSection(context),
        const SizedBox(height: 32),
        
        // Stats Grid for Web
        _buildWebStatsGrid(context),
        const SizedBox(height: 32),
        
        // Revenue and Quick Actions Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildWebRevenueSection(context),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 1,
              child: _buildWebQuickActions(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileDashboard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Section
        Consumer<AuthProvider>(
          builder: (context, authProvider, child) {
            final user = authProvider.currentUser;
            return Card(
              color: Colors.blue.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blue,
                      child: Text(
                        user?.firstName != null && user?.firstName.isNotEmpty == true ? user!.firstName[0].toUpperCase() : 'G',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, ${user?.firstName ?? 'Gym Owner'}!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (user?.gymName != null)
                            Text(
                              user!.decodedGymName,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        
        // Quick Stats
        const Text(
          'Quick Overview',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.3,
          children: [
            Consumer<MemberProvider>(
              builder: (context, memberProvider, child) {
                return _buildStatCard(
                  'Total Members',
                  '${memberProvider.members.length}',
                  Icons.people,
                  Colors.blue,
                );
              },
            ),
            Consumer<MemberProvider>(
              builder: (context, memberProvider, child) {
                final activeMembers = memberProvider.members.where((m) => m.isActive).length;
                return _buildStatCard(
                  'Active Members',
                  '$activeMembers',
                  Icons.person_add,
                  Colors.green,
                );
              },
            ),
            Consumer<TrainerProvider>(
              builder: (context, trainerProvider, child) {
                return _buildStatCard(
                  'Trainers',
                  '${trainerProvider.trainers.length}',
                  Icons.fitness_center,
                  Colors.orange,
                );
              },
            ),
            Consumer<EquipmentProvider>(
              builder: (context, equipmentProvider, child) {
                final workingEquipment = equipmentProvider.equipment.where((e) => e.isWorking).length;
                return _buildStatCard(
                  'Working Equipment',
                  '$workingEquipment',
                  Icons.sports_gymnastics,
                  Colors.purple,
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // Revenue Section
        Consumer<PaymentProvider>(
          builder: (context, paymentProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Revenue Overview',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.3,
                  children: [
                    _buildRevenueCard(
                      'Monthly Revenue',
                      '₹${paymentProvider.monthlyRevenue.toStringAsFixed(0)}',
                      Icons.calendar_month,
                      Colors.green,
                    ),
                    _buildRevenueCard(
                      'Today\'s Revenue',
                      '₹${paymentProvider.dailyRevenue.toStringAsFixed(0)}',
                      Icons.today,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        
        // Quick Actions
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2,
          children: [
            _buildActionCard(
              context,
              'Add Member',
              Icons.person_add,
              Colors.blue,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddMemberScreen()),
                );
              },
            ),
            _buildActionCard(
              context,
              'Record Payment',
              Icons.payment,
              Colors.green,
              () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreatePaymentScreen()),
                );
                
                // Force refresh all data when returning from payment creation
                _refreshData(context);
              },
            ),
            _buildActionCard(
              context,
              'QR Scanner',
              Icons.qr_code_scanner,
              Colors.orange,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                );
              },
            ),
            _buildActionCard(
              context,
              'Add Plan',
              Icons.card_membership,
              Colors.purple,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreateSubscriptionPlanScreen()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWebWelcomeSection(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        return Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.primaryBlue, AppTheme.primaryBlue.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(context.webCardBorderRadius),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                ),
                child: Center(
                  child: Text(
                    user?.firstName != null && user?.firstName.isNotEmpty == true 
                        ? user!.firstName[0].toUpperCase() 
                        : 'G',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back, ${user?.firstName ?? 'Gym Owner'}!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (user?.gymName != null)
                      Text(
                        user!.decodedGymName,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Today is ${_formatDate(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    Icons.dashboard,
                    color: Colors.white.withOpacity(0.8),
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebStatsGrid(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Consumer<MemberProvider>(
            builder: (context, memberProvider, child) {
              return _buildWebStatCard(
                'Total Members',
                '${memberProvider.members.length}',
                Icons.people,
                AppTheme.primaryBlue,
                '+${memberProvider.members.where((m) => _isThisWeek(DateTime.now())).length} this week',
                context,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Consumer<MemberProvider>(
            builder: (context, memberProvider, child) {
              final activeMembers = memberProvider.members.where((m) => m.isActive).length;
              return _buildWebStatCard(
                'Active Members',
                '$activeMembers',
                Icons.person_add,
                AppTheme.successGreen,
                '${((activeMembers / memberProvider.members.length) * 100).toStringAsFixed(1)}% of total',
                context,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Consumer<TrainerProvider>(
            builder: (context, trainerProvider, child) {
              return _buildWebStatCard(
                'Trainers',
                '${trainerProvider.trainers.length}',
                Icons.fitness_center,
                AppTheme.warningOrange,
                'All active',
                context,
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Consumer<EquipmentProvider>(
            builder: (context, equipmentProvider, child) {
              final workingEquipment = equipmentProvider.equipment.where((e) => e.isWorking).length;
              final totalEquipment = equipmentProvider.equipment.length;
              return _buildWebStatCard(
                'Equipment',
                '$workingEquipment / $totalEquipment',
                Icons.sports_gymnastics,
                Colors.purple,
                'Working condition',
                context,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebStatCard(String title, String value, IconData icon, Color color, String subtitle, BuildContext context) {
    return Card(
      elevation: context.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.webCardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                Icon(
                  Icons.trending_up,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebRevenueSection(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        return Card(
          elevation: context.cardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.webCardBorderRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revenue Analytics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildRevenueMetric(
                        'Today',
                        '₹${paymentProvider.dailyRevenue.toStringAsFixed(0)}',
                        Icons.today,
                        AppTheme.successGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildRevenueMetric(
                        'This Month',
                        '₹${paymentProvider.monthlyRevenue.toStringAsFixed(0)}',
                        Icons.calendar_month,
                        AppTheme.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          color: Colors.grey.shade400,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Revenue Chart',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
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

  Widget _buildRevenueMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebQuickActions(BuildContext context) {
    return Card(
      elevation: context.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.webCardBorderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            _buildWebActionButton(
              context,
              'Add New Member',
              Icons.person_add,
              AppTheme.primaryBlue,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddMemberScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildWebActionButton(
              context,
              'Record Payment',
              Icons.payment,
              AppTheme.successGreen,
              () async {
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreatePaymentScreen()),
                );
                _refreshData(context);
              },
            ),
            const SizedBox(height: 12),
            _buildWebActionButton(
              context,
              'QR Scanner',
              Icons.qr_code_scanner,
              AppTheme.warningOrange,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const QRScannerScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildWebActionButton(
              context,
              'Create Plan',
              Icons.card_membership,
              Colors.purple,
              () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const CreateSubscriptionPlanScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebActionButton(BuildContext context, String title, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(context.webButtonBorderRadius),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  bool _isThisWeek(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return date.isAfter(weekAgo);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String title, String amount, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}