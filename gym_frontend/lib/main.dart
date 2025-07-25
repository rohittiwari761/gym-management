import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/members_screen.dart';
import 'screens/equipment_screen.dart';
import 'screens/trainers_screen.dart';
import 'screens/subscription_plans_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'services/api_service.dart';
import 'services/offline_handler.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/health_service.dart';
import 'services/keep_alive_service.dart';
import 'providers/member_provider.dart';
import 'providers/trainer_provider.dart';
import 'providers/equipment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/theme_provider.dart';
import 'utils/app_theme.dart';
import 'widgets/common_widgets.dart' as common_widgets;

void main() async {
  // Enable detailed error reporting
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Handle errors in async operations
  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };

  // Initialize services
  WidgetsFlutterBinding.ensureInitialized();
  
  // Pre-warm text input system to reduce first-tap delay
  await _preWarmTextInput();

  // Reset offline state on app start
  OfflineHandler.reset();

  // Initialize API service
  final apiService = ApiService();
  apiService.initialize();

  // Initialize Auth service
  final authService = AuthService();
  authService.initialize();

  // Initialize Google Auth service
  final googleAuthService = GoogleAuthService();
  googleAuthService.initialize();

  // Initialize Keep-Alive service to prevent Railway server sleep
  final keepAliveService = KeepAliveService();
  keepAliveService.initialize();

  // Run health check on startup (async, don't block startup)
  HealthService.runFullHealthCheck().then((results) {
    // Health check completed
    print('✅ HEALTH_CHECK: Initial health check completed');
  }).catchError((error) {
    // Health check failed
    print('❌ HEALTH_CHECK: Initial health check failed: $error');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MemberProvider>(
          create: (_) => MemberProvider(),
          update: (_, auth, memberProvider) => memberProvider ?? MemberProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, TrainerProvider>(
          create: (_) => TrainerProvider(),
          update: (_, auth, trainerProvider) => trainerProvider ?? TrainerProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, EquipmentProvider>(
          create: (_) => EquipmentProvider(),
          update: (_, auth, equipmentProvider) => equipmentProvider ?? EquipmentProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SubscriptionProvider>(
          create: (_) => SubscriptionProvider(),
          update: (_, auth, subscriptionProvider) => subscriptionProvider ?? SubscriptionProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, PaymentProvider>(
          create: (_) => PaymentProvider(),
          update: (_, auth, paymentProvider) => paymentProvider ?? PaymentProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, UserProfileProvider>(
          create: (_) => UserProfileProvider(),
          update: (_, auth, userProfileProvider) => userProfileProvider ?? UserProfileProvider(),
        ),
        ChangeNotifierProxyProvider<AuthProvider, AttendanceProvider>(
          create: (_) => AttendanceProvider(),
          update: (_, auth, attendanceProvider) => attendanceProvider ?? AttendanceProvider(),
        ),
        Provider(create: (_) => ApiService()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Gym Management System',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthWrapper(),
            onGenerateRoute: _generateRoute,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Generate routes for named navigation
Route<dynamic> _generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
    case '/dashboard':
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    case '/members':
      return MaterialPageRoute(builder: (_) => const MembersScreen());
    case '/equipment':
      return MaterialPageRoute(builder: (_) => const EquipmentScreen());
    case '/trainers':
      return MaterialPageRoute(builder: (_) => const TrainersScreen());
    case '/subscriptions':
      return MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen());
    case '/payments':
      return MaterialPageRoute(builder: (_) => const PaymentsScreen());
    case '/attendance':
      return MaterialPageRoute(builder: (_) => const AttendanceScreen());
    case '/analytics':
      // Analytics screen doesn't exist yet, redirect to dashboard
      return MaterialPageRoute(builder: (_) => const HomeScreen());
    case '/settings':
      return MaterialPageRoute(builder: (_) => const SettingsScreen());
    case '/profile':
      return MaterialPageRoute(builder: (_) => const ProfileScreen());
    default:
      // Return a default route for unhandled routes
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Page Not Found')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Page Not Found',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Route: ${settings.name}',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(_, '/dashboard'),
                  child: const Text('Go to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final KeepAliveService _keepAliveService = KeepAliveService();

  @override
  void initState() {
    super.initState();
    // Listen to app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - restart keep-alive service
        print('📱 APP_LIFECYCLE: App resumed - restarting keep-alive service');
        _keepAliveService.initialize();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // App is in background - stop keep-alive service to save battery
        print('📱 APP_LIFECYCLE: App paused/inactive - stopping keep-alive service');
        _keepAliveService.stop();
        break;
      case AppLifecycleState.hidden:
        // App is hidden but still running
        print('📱 APP_LIFECYCLE: App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const common_widgets.LoadingWidget(
              message: 'Initializing Gym Management System...',
            ),
          );
        }

        return authProvider.isLoggedIn
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}

/// Pre-warm text input system to reduce first-tap delay on input fields
Future<void> _preWarmTextInput() async {
  try {
    // Initialize text input services
    await SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    // Pre-warm keyboard services (platform-specific)
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await SystemChannels.textInput.invokeMethod('TextInput.setClient', [
        -1, // Temporary client ID
        {
          'inputType': {'name': 'TextInputType.text'},
          'inputAction': 'TextInputAction.done',
        }
      ]);
      await SystemChannels.textInput.invokeMethod('TextInput.clearClient');
    }
    
    print('✅ TEXT_INPUT: Pre-warming completed successfully');
  } catch (e) {
    print('⚠️ TEXT_INPUT: Pre-warming failed (non-critical): $e');
    // Don't block app startup if pre-warming fails
  }
}
