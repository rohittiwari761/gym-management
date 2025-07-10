import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/offline_handler.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';
import 'services/health_service.dart';
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

  // Run health check on startup (async, don't block startup)
  HealthService.runFullHealthCheck().then((results) {
    // Health check completed
  }).catchError((error) {
    // Health check failed
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
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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
