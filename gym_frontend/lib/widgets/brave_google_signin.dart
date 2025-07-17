import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/brave_auth_service.dart';
import '../services/auth_service.dart';

class BraveGoogleSignIn extends StatefulWidget {
  final Function(Map<String, dynamic>) onSignInSuccess;
  final Function(String) onSignInError;
  final bool isLoading;

  const BraveGoogleSignIn({
    Key? key,
    required this.onSignInSuccess,
    required this.onSignInError,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<BraveGoogleSignIn> createState() => _BraveGoogleSignInState();
}

class _BraveGoogleSignInState extends State<BraveGoogleSignIn> {
  final BraveAuthService _braveAuthService = BraveAuthService();
  bool _isBraveBrowser = false;
  bool _isGoogleBlocked = false;
  bool _isCheckingBrowser = true;
  bool _isProcessingCallback = false;

  @override
  void initState() {
    super.initState();
    _checkBrowserAndGoogleAccess();
    _handleOAuthCallbackIfPresent();
  }

  void _checkBrowserAndGoogleAccess() async {
    setState(() {
      _isCheckingBrowser = true;
    });

    try {
      print('🔍 BRAVE_GOOGLE: Checking browser compatibility...');
      
      _isBraveBrowser = BraveAuthService.isBraveBrowser();
      _isGoogleBlocked = await BraveAuthService.isGoogleBlocked();
      
      print('🔍 BRAVE_GOOGLE: Is Brave browser: $_isBraveBrowser');
      print('🔍 BRAVE_GOOGLE: Is Google blocked: $_isGoogleBlocked');
      
      setState(() {
        _isCheckingBrowser = false;
      });
    } catch (e) {
      print('❌ BRAVE_GOOGLE: Error checking browser: $e');
      setState(() {
        _isCheckingBrowser = false;
        _isBraveBrowser = true; // Assume Brave to show alternative
        _isGoogleBlocked = true;
      });
    }
  }

  void _handleOAuthCallbackIfPresent() async {
    if (!BraveAuthService.isOAuthCallback()) return;

    setState(() {
      _isProcessingCallback = true;
    });

    try {
      print('🔄 BRAVE_GOOGLE: Processing OAuth callback...');
      
      final callback = BraveAuthService.handleOAuthCallback();
      if (callback == null) {
        print('⚠️ BRAVE_GOOGLE: No callback data found');
        return;
      }

      if (callback.containsKey('error')) {
        final error = callback['error']!;
        print('❌ BRAVE_GOOGLE: OAuth error: $error');
        widget.onSignInError('Google Sign-In failed: $error');
        BraveAuthService.cleanOAuthUrl();
        return;
      }

      if (callback.containsKey('code')) {
        final code = callback['code']!;
        print('✅ BRAVE_GOOGLE: Processing OAuth code...');
        
        final result = await _braveAuthService.exchangeCodeForTokens(code);
        
        if (result['success'] == true) {
          print('✅ BRAVE_GOOGLE: Authentication successful');
          
          // Store auth data using AuthService
          final authService = AuthService();
          await authService.loginWithGoogleData(
            userData: result['user'],
            token: result['token'],
            isPersistentSession: true,
          );
          
          BraveAuthService.cleanOAuthUrl();
          widget.onSignInSuccess(result);
        } else {
          print('❌ BRAVE_GOOGLE: Authentication failed: ${result['error']}');
          widget.onSignInError(result['error'] ?? 'Authentication failed');
          BraveAuthService.cleanOAuthUrl();
        }
      }
    } catch (e) {
      print('❌ BRAVE_GOOGLE: Error processing callback: $e');
      widget.onSignInError('Error processing Google Sign-In: $e');
      BraveAuthService.cleanOAuthUrl();
    } finally {
      setState(() {
        _isProcessingCallback = false;
      });
    }
  }

  void _performBraveGoogleSignIn() {
    try {
      print('🚀 BRAVE_GOOGLE: Starting Brave-friendly Google Sign-In...');
      
      // Open Google OAuth in new tab
      BraveAuthService.openGoogleAuthInNewTab();
      
      // Show instructions to user
      _showBraveInstructions();
      
    } catch (e) {
      print('❌ BRAVE_GOOGLE: Error starting sign-in: $e');
      widget.onSignInError('Failed to start Google Sign-In: $e');
    }
  }

  void _showBraveInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.blue),
            SizedBox(width: 8),
            Text('Brave Browser Sign-In'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Sign-In opened in a new tab to work with Brave\'s privacy features.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text('After signing in with Google:'),
            SizedBox(height: 8),
            _buildInstructionItem('1. Complete Google Sign-In in the new tab'),
            _buildInstructionItem('2. Return to this tab'),
            _buildInstructionItem('3. You\'ll be automatically signed in'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This method bypasses Brave\'s ad/tracker blocking while keeping you secure.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(top: 6, right: 8),
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main Sign-In Button
        Container(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: _getButtonAction(),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: _getButtonColor(), 
                width: 2
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: _getButtonBackgroundColor(),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: _getButtonIcon(),
            label: Text(
              _getButtonText(),
              style: TextStyle(color: _getButtonColor()),
            ),
          ),
        ),
        
        SizedBox(height: 8),
        
        // Status Widget
        _buildStatusWidget(),
      ],
    );
  }

  VoidCallback? _getButtonAction() {
    if (widget.isLoading || _isCheckingBrowser || _isProcessingCallback) {
      return null;
    }
    
    if (_isBraveBrowser || _isGoogleBlocked) {
      return _performBraveGoogleSignIn;
    }
    
    return null; // Will fall back to standard Google Sign-In
  }

  Color _getButtonColor() {
    if (_isCheckingBrowser || _isProcessingCallback) {
      return Colors.grey;
    } else if (_isBraveBrowser || _isGoogleBlocked) {
      return Colors.purple; // Different color for Brave mode
    } else {
      return Colors.red;
    }
  }

  Color _getButtonBackgroundColor() {
    if (_isCheckingBrowser || _isProcessingCallback) {
      return Colors.grey[100]!;
    } else if (_isBraveBrowser || _isGoogleBlocked) {
      return Colors.purple[50]!;
    } else {
      return Colors.red[50]!;
    }
  }

  Widget _getButtonIcon() {
    if (widget.isLoading || _isProcessingCallback) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: _getButtonColor()),
      );
    } else if (_isCheckingBrowser) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
      );
    } else if (_isBraveBrowser || _isGoogleBlocked) {
      return Icon(Icons.security, color: _getButtonColor(), size: 24);
    } else {
      return Icon(Icons.account_circle, color: _getButtonColor(), size: 24);
    }
  }

  String _getButtonText() {
    if (_isProcessingCallback) {
      return 'Processing Sign-In...';
    } else if (widget.isLoading) {
      return 'Signing in...';
    } else if (_isCheckingBrowser) {
      return 'Checking Browser Compatibility...';
    } else if (_isBraveBrowser || _isGoogleBlocked) {
      return 'Continue with Google (Brave Safe)';
    } else {
      return 'Continue with Google';
    }
  }

  Widget _buildStatusWidget() {
    if (_isProcessingCallback) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Processing Google Sign-In from new tab...',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_isCheckingBrowser) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Checking browser compatibility and Google access...',
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (_isBraveBrowser || _isGoogleBlocked) {
      return Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.purple.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.security, color: Colors.purple.shade600, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                _isBraveBrowser 
                    ? 'Brave browser detected. Using privacy-friendly sign-in method.'
                    : 'Google services blocked. Using alternative sign-in method.',
                style: TextStyle(
                  color: Colors.purple.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return SizedBox.shrink();
  }
}