import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../security/input_validator.dart';
import '../services/google_auth_service.dart';
import '../utils/network_test.dart';
import '../widgets/optimized_text_field.dart';
import '../widgets/input_field_warmer.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TextFieldOptimizationMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState(); // This will call the mixin's initState
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;

    return InputFieldWarmer(
      child: Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top spacing for larger screens
                      if (!isSmallScreen) const Spacer(flex: 1),
                      
                      // Content card
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 20.0 : 32.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                        Icon(
                          Icons.fitness_center,
                          size: isSmallScreen ? 60.0 : 80.0,
                          color: Colors.blue,
                        ),
                        SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                        Text(
                          'Gym Management',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Login to manage your gym',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 20.0 : 32.0),
                        OptimizedTextFields.email(
                          controller: _emailController,
                          autofocus: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            final validation = InputValidator.validateEmail(value);
                            return validation.isValid ? null : validation.message;
                          },
                        ),
                        const SizedBox(height: 20),
                        OptimizedTextFields.password(
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            final errorMessage = authProvider.errorMessage;
                            if (errorMessage != null) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errorMessage),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                authProvider.clearError();
                              });
                            }

                            return SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: authProvider.isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: authProvider.isLoading
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : const Text('Login'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Google Sign-In Button (available on all platforms)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => _signInWithGoogle(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              backgroundColor: Colors.red[50],
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            icon: const Icon(
                              Icons.account_circle,
                              color: Colors.red,
                              size: 24,
                            ),
                            label: const Text(
                              'Continue with Google',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Divider (available on all platforms)
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey[400])),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey[400])),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Login info hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Getting Started',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text('• Create a new account using the register button below'),
                              const Text('• Or use Google Sign-In for quick access'),
                              if (kIsWeb) const Text('• Web version now supports Google Sign-In'),
                              const SizedBox(height: 8),
                              Text(
                                'Backend: gym-management-production-4343.up.railway.app',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              if (kIsWeb) 
                                Text(
                                  '⚠️ If login fails, Railway backend may need redeployment',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.blue, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('Create New Account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                      ),
                      
                      // Bottom spacing for larger screens
                      if (!isSmallScreen) const Spacer(flex: 1),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Add network test before attempting login
      print('🔍 LOGIN: Starting network test before login...');
      await NetworkTest.testNetworkConnection();
      
      final result = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (result['success'] == true && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        // Additional error information is already handled by AuthProvider
        // and displayed via the Consumer<AuthProvider> error handling above
      }
    } else {
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Show loading indicator
      authProvider.setLoading(true);
      
      // Initialize Google Auth Service if not already done
      final googleAuthService = GoogleAuthService();
      googleAuthService.initialize();
      
      final result = await googleAuthService.signInWithGoogle();
      
      // Handle both boolean true and string 'true'
      bool isSuccess = result['success'] == true || result['success'] == 'true';
      
      if (isSuccess) {
        // Google sign-in successful - force immediate navigation
        // Wait for the auth service to store the data
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Force AuthProvider to check login status multiple times with longer delays
        await authProvider.checkLoginStatus();
        
        // Check if we're now logged in
        if (authProvider.isLoggedIn) {
          // Navigation should happen automatically via AuthWrapper
          authProvider.setLoading(false);
          return;
        }
        
        // Additional retry attempts with longer delays
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          await authProvider.checkLoginStatus();
          
          if (authProvider.isLoggedIn) {
            authProvider.setLoading(false);
            return;
          }
        }
        
        // If still not logged in, force manual navigation
        if (mounted) {
          authProvider.setLoading(false);
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
        
        return;
      } else {
        authProvider.setLoading(false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Google sign-in failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setLoading(false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToHomeAlternative() {
    print('🔄 GOOGLE SIGNIN: Attempting alternative navigation to home screen');
    
    // Try to use the navigator key from the app's main context
    try {
      // Since the user is authenticated, we can trigger app restart or use a different method
      // For now, we'll show a success message and let the user manually go to home
      print('✅ GOOGLE SIGNIN: User successfully authenticated - app should refresh automatically');
    } catch (e) {
      print('❌ GOOGLE SIGNIN: Alternative navigation also failed: $e');
    }
  }
}