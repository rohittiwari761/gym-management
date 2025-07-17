import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/google_auth_service.dart';

class InlineGoogleSignIn extends StatefulWidget {
  final Function(Map<String, dynamic>) onSignInSuccess;
  final Function(String) onSignInError;
  final bool isLoading;

  const InlineGoogleSignIn({
    Key? key,
    required this.onSignInSuccess,
    required this.onSignInError,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<InlineGoogleSignIn> createState() => _InlineGoogleSignInState();
}

class _InlineGoogleSignInState extends State<InlineGoogleSignIn> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  bool _isInitialized = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeGoogleAuth();
  }

  void _initializeGoogleAuth() async {
    if (_isInitializing) return;
    
    setState(() {
      _isInitializing = true;
    });

    try {
      print('🔄 INLINE_GOOGLE: Initializing Google Auth Service...');
      _googleAuthService.initialize();
      
      // Pre-warm the Google Sign-In to reduce popup blocker issues
      if (kIsWeb) {
        try {
          await _googleAuthService.isSignedIn();
          print('✅ INLINE_GOOGLE: Google Sign-In pre-warmed successfully');
        } catch (e) {
          print('⚠️ INLINE_GOOGLE: Pre-warm failed (expected): $e');
        }
      }

      setState(() {
        _isInitialized = true;
        _isInitializing = false;
      });

      print('✅ INLINE_GOOGLE: Initialization complete');
    } catch (e) {
      print('❌ INLINE_GOOGLE: Initialization failed: $e');
      setState(() {
        _isInitializing = false;
      });
      widget.onSignInError('Failed to initialize Google Sign-In: $e');
    }
  }

  void _performGoogleSignIn() async {
    if (!_isInitialized || widget.isLoading) {
      print('⚠️ INLINE_GOOGLE: Not ready for sign-in');
      return;
    }

    try {
      print('🚀 INLINE_GOOGLE: Starting Google Sign-In process...');
      
      // Try to sign in with enhanced error handling
      final result = await _googleAuthService.signInWithGoogle();
      
      print('📥 INLINE_GOOGLE: Sign-in result received: $result');
      
      if (result['success'] == true) {
        print('✅ INLINE_GOOGLE: Sign-in successful');
        widget.onSignInSuccess(result);
      } else {
        print('❌ INLINE_GOOGLE: Sign-in failed: ${result['error']}');
        final errorMessage = result['error'] ?? 'Google Sign-In failed';
        
        // Check if it's an ad blocker issue and provide specific guidance
        if (errorMessage.contains('blocked') || 
            errorMessage.contains('popup') ||
            errorMessage.contains('ERR_BLOCKED_BY_CLIENT')) {
          widget.onSignInError('Google Sign-In was blocked. Please:\n\n• Disable ad blockers for this site\n• Allow popups for this domain\n• Try using incognito/private mode\n• Or use email registration instead');
        } else {
          widget.onSignInError(errorMessage);
        }
      }
    } catch (e) {
      print('💥 INLINE_GOOGLE: Exception during sign-in: $e');
      widget.onSignInError('Google Sign-In error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main Google Sign-In Button
        Container(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: (widget.isLoading || !_isInitialized) ? null : _performGoogleSignIn,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _isInitialized ? Colors.red : Colors.grey, 
                width: 2
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: _isInitialized ? Colors.red[50] : Colors.grey[100],
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: _getButtonIcon(),
            label: Text(
              _getButtonText(),
              style: TextStyle(
                color: _isInitialized ? Colors.red : Colors.grey[600],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Status and guidance
        _buildStatusWidget(),
      ],
    );
  }

  Widget _getButtonIcon() {
    if (widget.isLoading) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
      );
    } else if (_isInitializing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      );
    } else {
      return Icon(
        Icons.account_circle, 
        color: _isInitialized ? Colors.red : Colors.grey[600],
        size: 24,
      );
    }
  }

  String _getButtonText() {
    if (widget.isLoading) {
      return 'Signing in...';
    } else if (_isInitializing) {
      return 'Initializing Google Sign-In...';
    } else if (!_isInitialized) {
      return 'Google Sign-In Unavailable';
    } else {
      return 'Continue with Google';
    }
  }

  Widget _buildStatusWidget() {
    if (_isInitializing) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Preparing Google Sign-In to minimize ad blocker interference...',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_isInitialized && kIsWeb) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Google Sign-In ready. If blocked, try disabling ad blockers.',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (!_isInitialized) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade600, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Google Sign-In initialization failed. Please check your connection.',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}