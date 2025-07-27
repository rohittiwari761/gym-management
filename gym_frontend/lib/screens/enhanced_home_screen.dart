import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../providers/trainer_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/subscription_provider.dart';
import '../providers/attendance_provider.dart';
import '../utils/responsive_utils.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/enhanced_dashboard.dart';
import '../screens/optimized_members_screen.dart';
import '../screens/optimized_trainers_screen.dart';
import '../screens/equipment_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/subscription_plans_screen.dart';
import '../screens/payments_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/add_member_screen.dart';
import '../screens/create_payment_screen.dart';
import '../screens/login_screen.dart';

class EnhancedHomeScreen extends StatefulWidget {
  const EnhancedHomeScreen({super.key});

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  String _currentRoute = 'dashboard';
  Widget? _currentScreen;

  @override
  void initState() {
    super.initState();
    _currentScreen = const EnhancedDashboard();
    
    // Defer data loading to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    try {
      print('🔄 HOME: Starting data loading...');
      
      // Phase 1: Load critical data first (blocking)
      await Future.wait([
        context.read<MemberProvider>().fetchMembers(),
        context.read<AttendanceProvider>().fetchAttendances(),
      ]);
      
      print('✅ HOME: Critical data loaded');

      // Phase 2: Load important data (background, non-blocking)
      if (mounted) {
        Future.wait([
          context.read<TrainerProvider>().fetchTrainers(),
          context.read<EquipmentProvider>().fetchEquipment(),
        ], eagerError: false).catchError((e) {
          if (kDebugMode) print('Secondary data loading error: $e');
        });
      }

      // Phase 3: Load analytics data (lowest priority, background)
      if (mounted) {
        Future.wait([
          context.read<SubscriptionProvider>().fetchSubscriptionPlans(),
          context.read<PaymentProvider>().fetchRevenueAnalytics(),
        ], eagerError: false).catchError((e) {
          if (kDebugMode) print('Analytics data loading error: $e');
        });
      }
      
      print('🎉 HOME: All data loading initiated successfully');
    } catch (e) {
      if (kDebugMode) print('Critical data loading error: $e');
    }
  }

  void _onRouteSelected(String route) {
    setState(() {
      _currentRoute = route;
      _currentScreen = _getScreenForRoute(route);
    });
  }

  Widget _getScreenForRoute(String route) {
    switch (route) {
      case 'dashboard':
        return const EnhancedDashboard();
      case 'members':
        return const OptimizedMembersScreen();
      case 'trainers':
        return const OptimizedTrainersScreen();
      case 'equipment':
        return const EquipmentScreen();
      case 'attendance':
        return const AttendanceScreen();
      case 'subscription-plans':
        return const SubscriptionPlansScreen();
      case 'payments':
        return const PaymentsScreen();
      case 'profile':
        return const ProfileScreen();
      case 'settings':
        return const SettingsScreen();
      default:
        return const EnhancedDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobileBody: _buildMobileLayout(),
      desktopBody: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym Management'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: _buildMobileDrawer(),
      body: _currentScreen ?? const EnhancedDashboard(),
    );
  }

  Widget _buildDesktopLayout() {
    return WebSidebarLayout(
      sidebar: WebSidebar(
        onItemSelected: _onRouteSelected,
        currentRoute: _currentRoute,
      ),
      body: Scaffold(
        appBar: _buildDesktopAppBar(),
        body: _currentScreen ?? const EnhancedDashboard(),
      ),
    );
  }

  PreferredSizeWidget _buildDesktopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.grey[800],
      elevation: 1,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Text(
            _getPageTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Search bar
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search members, trainers...',
                prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // User profile
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final user = authProvider.currentUser;
              final userName = user != null ? '${user.firstName} ${user.lastName}' : 'User';
              
              return PopupMenuButton<String>(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 20),
                        SizedBox(width: 8),
                        Text('Profile'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 20),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Logout', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog();
                  } else if (value == 'profile') {
                    _onRouteSelected('profile');
                  } else if (value == 'settings') {
                    _onRouteSelected('settings');
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Column(
        children: [
          // Header
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
                final userName = user != null ? '${user.firstName} ${user.lastName}' : 'Loading...';
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
                  route: 'dashboard',
                ),
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Members',
                  route: 'members',
                ),
                _buildDrawerItem(
                  icon: Icons.fitness_center,
                  title: 'Trainers',
                  route: 'trainers',
                ),
                _buildDrawerItem(
                  icon: Icons.sports_gymnastics,
                  title: 'Equipment',
                  route: 'equipment',
                ),
                _buildDrawerItem(
                  icon: Icons.checklist,
                  title: 'Attendance',
                  route: 'attendance',
                ),
                _buildDrawerItem(
                  icon: Icons.card_membership,
                  title: 'Subscription Plans',
                  route: 'subscription-plans',
                ),
                _buildDrawerItem(
                  icon: Icons.payment,
                  title: 'Payments',
                  route: 'payments',
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  route: 'profile',
                ),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  route: 'settings',
                ),
                _buildDrawerItem(
                  icon: Icons.logout,
                  title: 'Logout',
                  route: 'logout',
                  isLogout: true,
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
    required String route,
    bool isLogout = false,
  }) {
    final isSelected = _currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : (isSelected ? Colors.blue : Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isLogout ? Colors.red : (isSelected ? Colors.blue : Colors.grey[800]),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onTap: () {
        Navigator.pop(context);
        if (isLogout) {
          _showLogoutDialog();
        } else {
          _onRouteSelected(route);
        }
      },
    );
  }

  String _getPageTitle() {
    switch (_currentRoute) {
      case 'dashboard':
        return 'Dashboard';
      case 'members':
        return 'Members';
      case 'trainers':
        return 'Trainers';
      case 'equipment':
        return 'Equipment';
      case 'attendance':
        return 'Attendance';
      case 'subscription-plans':
        return 'Subscription Plans';
      case 'payments':
        return 'Payments';
      case 'profile':
        return 'Profile';
      case 'settings':
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  void _showLogoutDialog() {
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
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logoutWithDataClear(context);
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}