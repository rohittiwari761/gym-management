import 'package:flutter/material.dart';
import 'password_strength_indicator.dart';
import '../security/input_validator.dart';

class EnhancedPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool showStrengthIndicator;
  final bool showRequirements;
  final FormFieldValidator<String>? validator;
  final Function(String)? onChanged;
  final bool isConfirmPassword;
  final String? originalPassword;

  const EnhancedPasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.hintText,
    this.showStrengthIndicator = true,
    this.showRequirements = true,
    this.validator,
    this.onChanged,
    this.isConfirmPassword = false,
    this.originalPassword,
  });

  @override
  State<EnhancedPasswordField> createState() => _EnhancedPasswordFieldState();
}

class _EnhancedPasswordFieldState extends State<EnhancedPasswordField> {
  bool _obscureText = true;
  String _currentPassword = '';

  @override
  void initState() {
    super.initState();
    _currentPassword = widget.controller.text;
    widget.controller.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _currentPassword = widget.controller.text;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(_currentPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[600],
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.grey[600],
            ),
            errorMaxLines: 3,
          ),
          validator: widget.validator ??
              (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter ${widget.labelText.toLowerCase()}';
                }
                
                if (widget.isConfirmPassword) {
                  if (value != widget.originalPassword) {
                    return 'Passwords do not match';
                  }
                  return null;
                }
                
                final validation = InputValidator.validatePassword(value);
                return validation.isValid ? null : validation.message;
              },
        ),
        
        // Show password strength indicator only for main password field
        if (widget.showStrengthIndicator && !widget.isConfirmPassword && _currentPassword.isNotEmpty) ...[
          const SizedBox(height: 8),
          PasswordStrengthIndicator(
            password: _currentPassword,
            showRequirements: widget.showRequirements,
          ),
        ],
        
        // Show password match indicator for confirm password
        if (widget.isConfirmPassword && _currentPassword.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _currentPassword == widget.originalPassword
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 16,
                color: _currentPassword == widget.originalPassword
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                _currentPassword == widget.originalPassword
                    ? 'Passwords match'
                    : 'Passwords do not match',
                style: TextStyle(
                  fontSize: 12,
                  color: _currentPassword == widget.originalPassword
                      ? Colors.green[700]
                      : Colors.red[700],
                ),
              ),
            ],
          ),
        ],
        
        // Show helpful tips
        if (!widget.isConfirmPassword && _currentPassword.isEmpty && widget.showRequirements) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Password Requirements:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRequirementTip('At least 8 characters long'),
                _buildRequirementTip('At least one uppercase letter (A-Z)'),
                _buildRequirementTip('At least one lowercase letter (a-z)'),
                _buildRequirementTip('At least one number (0-9)'),
                _buildRequirementTip('At least one special character (!@#\$%^&*)'),
                _buildRequirementTip('Avoid common passwords'),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRequirementTip(String requirement) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 4,
            color: Colors.blue[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PasswordStrengthValidator {
  static String? validatePasswordStrength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    final validation = InputValidator.validatePassword(value);
    if (!validation.isValid) {
      return validation.message;
    }
    
    // Additional real-time feedback
    final requirements = PasswordRequirementChecker.checkRequirements(value);
    if (!requirements.values.every((met) => met)) {
      return PasswordRequirementChecker.getPasswordFeedback(value);
    }
    
    return null;
  }
  
  static String? validatePasswordConfirmation(String? value, String originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }
}