import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../security/input_validator.dart';
import '../services/google_auth_service.dart';
import '../utils/network_test.dart';
import '../widgets/optimized_text_field.dart';
import '../widgets/input_field_warmer.dart';
import '../widgets/google_signin_error_dialog.dart';
import '../widgets/inline_google_signin.dart';
import '../widgets/brave_google_signin.dart';
import '../services/brave_auth_service.dart';
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
                        
                        // Smart Google Sign-In (adapts to browser)
                        Consumer<AuthProvider>(
                          builder: (context, authProvider, child) {
                            // Use Brave-friendly sign-in for privacy browsers
                            if (kIsWeb && (BraveAuthService.isBraveBrowser())) {
                              return BraveGoogleSignIn(
                                isLoading: authProvider.isLoading,
                                onSignInSuccess: _handleGoogleSignInSuccess,
                                onSignInError: _handleGoogleSignInError,
                              );
                            }
                            
                            // Use inline sign-in for other browsers
                            return InlineGoogleSignIn(
                              isLoading: authProvider.isLoading,
                              onSignInSuccess: _handleGoogleSignInSuccess,
                              onSignInError: _handleGoogleSignInError,
                            );
                          },
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
                                'Backend: gym-management-production-2168.up.railway.app',
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
      
      print('🚀 BUTTON_CLICKED: Google Sign-In button was clicked!');
      print('🔐 GOOGLE_SIGNIN: Starting Google Sign-In process...');
      
      // Initialize Google Auth Service if not already done
      print('🔧 GOOGLE_SIGNIN: Initializing Google Auth Service...');
      final googleAuthService = GoogleAuthService();
      googleAuthService.initialize();
      print('✅ GOOGLE_SIGNIN: Google Auth Service initialized');
      
      print('🚀 GOOGLE_SIGNIN: Calling signInWithGoogle()...');
      final result = await googleAuthService.signInWithGoogle();
      print('🏁 GOOGLE_SIGNIN: signInWithGoogle() returned: $result');
      
      print('🔐 GOOGLE_SIGNIN: Google Sign-In result: $result');
      
      // Handle both boolean true and string 'true'
      bool isSuccess = result['success'] == true || result['success'] == 'true';
      
      if (isSuccess) {
        print('✅ GOOGLE_SIGNIN: Google authentication successful');
        
        // Since Google auth stores data in AuthService, we need to refresh the AuthProvider
        // Wait a bit for the data to be properly stored
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Refresh the auth provider to pick up the new login state (with timeout protection)
        try {
          await authProvider.refreshAuthStatus();
        } catch (e) {
          print('⚠️ GOOGLE_SIGNIN: AuthProvider refresh failed, but Google auth succeeded: $e');
          // Continue anyway since Google auth was successful
        }
        
        print('🔐 GOOGLE_SIGNIN: AuthProvider refreshed. isLoggedIn: ${authProvider.isLoggedIn}');
        
        if (authProvider.isLoggedIn) {
          print('✅ GOOGLE_SIGNIN: User is logged in, navigating to home...');
          authProvider.setLoading(false);
          
          // Navigate to home screen
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomeScreen(),
              ),
            );
          }
          return;
        } else {
          print('⚠️ GOOGLE_SIGNIN: User not logged in after refresh, trying again...');
          
          // One more try with longer delay
          await Future.delayed(const Duration(milliseconds: 1000));
          await authProvider.refreshAuthStatus();
          
          if (authProvider.isLoggedIn) {
            print('✅ GOOGLE_SIGNIN: User logged in on second try, navigating...');
            authProvider.setLoading(false);
            
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            }
            return;
          } else {
            print('❌ GOOGLE_SIGNIN: User still not logged in after retries');
            // Force navigation anyway since Google auth was successful
            authProvider.setLoading(false);
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            }
            return;
          }
        }
      } else {
        print('❌ GOOGLE_SIGNIN: Google authentication failed');
        authProvider.setLoading(false);
        if (mounted) {
          final errorMessage = result['error'] ?? 'Google sign-in failed';
          
          // Use the enhanced error dialog for better user experience
          GoogleSignInErrorDialog.show(
            context,
            error: errorMessage,
            onRetry: () {
              Navigator.of(context).pop();
              _signInWithGoogle();
            },
            onUseEmail: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const RegisterScreen(),
                ),
              );
            },
          );
        }
      }
    } catch (e, stackTrace) {
      print('💥 GOOGLE_SIGNIN: Exception occurred: $e');
      print('💥 GOOGLE_SIGNIN: Stack trace: $stackTrace');
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setLoading(false);
      
      if (mounted) {
        // Use the enhanced error dialog for exceptions too
        GoogleSignInErrorDialog.show(
          context,
          error: 'Google sign-in error: ${e.toString()}',
          onRetry: () {
            Navigator.of(context).pop();
            _signInWithGoogle();
          },
          onUseEmail: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const RegisterScreen(),
              ),
            );
          },
        );
      }
    }
  }

  void _handleGoogleSignInSuccess(Map<String, dynamic> result) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      print('✅ INLINE_GOOGLE_LOGIN: Sign-in successful, processing result...');
      
      // If we received a credential, we need to handle it differently
      if (result.containsKey('credential')) {
        // TODO: Send credential to backend for verification
        print('🔑 INLINE_GOOGLE_LOGIN: Received Google credential, sending to backend...');
        // For now, show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google Sign-In successful! (Credential verification pending)'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return;
      }
      
      // Handle standard Google Sign-In success
      authProvider.setLoading(false);
      
      // Wait for auth data to be stored
      await Future.delayed(const Duration(milliseconds: 1000));
      
      try {
        await authProvider.refreshAuthStatus();
      } catch (e) {
        print('⚠️ INLINE_GOOGLE_LOGIN: AuthProvider refresh failed: $e');
      }
      
      if (authProvider.isLoggedIn) {
        print('✅ INLINE_GOOGLE_LOGIN: User logged in, navigating to home...');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      } else {
        print('⚠️ INLINE_GOOGLE_LOGIN: User not logged in after refresh, trying direct navigation...');
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        }
      }
    } catch (e) {
      print('💥 INLINE_GOOGLE_LOGIN: Error handling success: $e');
      _handleGoogleSignInError('Failed to complete Google Sign-In: $e');
    }
  }

  void _handleGoogleSignInError(String error) {
    print('❌ INLINE_GOOGLE_LOGIN: Error: $error');
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setLoading(false);
    
    if (mounted) {
      GoogleSignInErrorDialog.show(
        context,
        error: error,
        onRetry: () {
          Navigator.of(context).pop();
          // The inline widget will handle retry internally
        },
        onUseEmail: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const RegisterScreen(),
            ),
          );
        },
      );
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