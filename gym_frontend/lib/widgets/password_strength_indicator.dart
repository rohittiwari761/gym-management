import 'package:flutter/material.dart';
import '../security/security_config.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showRequirements;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showRequirements = true,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = _getPasswordRequirements(password);
    final strength = _calculatePasswordStrength(requirements);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (password.isNotEmpty) ...[
          const SizedBox(height: 8),
          // Password strength bar
          Row(
            children: [
              const Text(
                'Password Strength: ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: Colors.grey[300],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: strength >= 1 ? 1 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(3),
                              bottomLeft: Radius.circular(3),
                            ),
                            color: _getStrengthColor(strength),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: strength >= 2 ? 1 : 0,
                        child: Container(
                          color: strength >= 2 ? _getStrengthColor(strength) : Colors.transparent,
                        ),
                      ),
                      Expanded(
                        flex: strength >= 3 ? 1 : 0,
                        child: Container(
                          color: strength >= 3 ? _getStrengthColor(strength) : Colors.transparent,
                        ),
                      ),
                      Expanded(
                        flex: strength >= 4 ? 1 : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                            color: strength >= 4 ? _getStrengthColor(strength) : Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStrengthText(strength),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStrengthColor(strength),
                ),
              ),
            ],
          ),
          if (showRequirements) ...[
            const SizedBox(height: 12),
            // Requirements list
            ...requirements.entries.map((entry) => _buildRequirementItem(
              entry.key,
              entry.value,
            )),
          ],
        ],
      ],
    );
  }

  Widget _buildRequirementItem(String requirement, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? Colors.green : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              requirement,
              style: TextStyle(
                fontSize: 12,
                color: isMet ? Colors.green[700] : Colors.grey[600],
                decoration: isMet ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, bool> _getPasswordRequirements(String password) {
    return {
      'At least ${SecurityConfig.minPasswordLength} characters': password.length >= SecurityConfig.minPasswordLength,
      'At least one uppercase letter (A-Z)': SecurityConfig.requireUppercase ? password.contains(RegExp(r'[A-Z]')) : true,
      'At least one lowercase letter (a-z)': SecurityConfig.requireLowercase ? password.contains(RegExp(r'[a-z]')) : true,
      'At least one number (0-9)': SecurityConfig.requireNumbers ? password.contains(RegExp(r'[0-9]')) : true,
      'At least one special character (!@#\$%^&*)': SecurityConfig.requireSpecialChars ? password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) : true,
      'No common passwords': !_isCommonPassword(password),
    };
  }

  int _calculatePasswordStrength(Map<String, bool> requirements) {
    final metRequirements = requirements.values.where((met) => met).length;
    final totalRequirements = requirements.length;
    
    if (metRequirements == totalRequirements) {
      return 4; // Strong
    } else if (metRequirements >= totalRequirements * 0.75) {
      return 3; // Good
    } else if (metRequirements >= totalRequirements * 0.5) {
      return 2; // Fair
    } else if (metRequirements > 0) {
      return 1; // Weak
    } else {
      return 0; // Very weak
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStrengthText(int strength) {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', '12345678', '111111', '1234567890',
      'admin', 'letmein', 'welcome', 'monkey', '1234567',
      'password1', 'admin123', 'welcome123', 'guest', 'user',
      '12345', 'iloveyou', 'princess', 'admin', 'welcome',
      '666666', 'sunshine', 'master', 'shadow', 'monkey',
      'lovely', 'flower', 'daniel', 'hello', 'freedom',
    ];
    
    return commonPasswords.contains(password.toLowerCase());
  }
}

class PasswordRequirementChecker {
  static Map<String, bool> checkRequirements(String password) {
    return {
      'length': password.length >= SecurityConfig.minPasswordLength,
      'uppercase': SecurityConfig.requireUppercase ? password.contains(RegExp(r'[A-Z]')) : true,
      'lowercase': SecurityConfig.requireLowercase ? password.contains(RegExp(r'[a-z]')) : true,
      'number': SecurityConfig.requireNumbers ? password.contains(RegExp(r'[0-9]')) : true,
      'special': SecurityConfig.requireSpecialChars ? password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')) : true,
      'notCommon': !_isCommonPassword(password),
    };
  }

  static bool isPasswordValid(String password) {
    final requirements = checkRequirements(password);
    return requirements.values.every((met) => met);
  }

  static String getPasswordFeedback(String password) {
    final requirements = checkRequirements(password);
    final unmetRequirements = <String>[];

    if (!requirements['length']!) {
      unmetRequirements.add('at least ${SecurityConfig.minPasswordLength} characters');
    }
    if (!requirements['uppercase']!) {
      unmetRequirements.add('an uppercase letter');
    }
    if (!requirements['lowercase']!) {
      unmetRequirements.add('a lowercase letter');
    }
    if (!requirements['number']!) {
      unmetRequirements.add('a number');
    }
    if (!requirements['special']!) {
      unmetRequirements.add('a special character');
    }
    if (!requirements['notCommon']!) {
      unmetRequirements.add('a stronger, less common password');
    }

    if (unmetRequirements.isEmpty) {
      return 'Password meets all requirements';
    } else if (unmetRequirements.length == 1) {
      return 'Password needs ${unmetRequirements.first}';
    } else {
      return 'Password needs: ${unmetRequirements.join(', ')}';
    }
  }

  static bool _isCommonPassword(String password) {
    final commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', '12345678', '111111', '1234567890',
      'admin', 'letmein', 'welcome', 'monkey', '1234567',
      'password1', 'admin123', 'welcome123', 'guest', 'user',
    ];
    
    return commonPasswords.contains(password.toLowerCase());
  }
}