import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/enhanced_password_field.dart';
import '../security/input_validator.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gymNameController = TextEditingController();
  final _gymAddressController = TextEditingController();
  final _gymDescriptionController = TextEditingController();
  String _currentPassword = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _gymNameController.dispose();
    _gymAddressController.dispose();
    _gymDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700 || screenWidth < 400;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 12.0 : 24.0),
            child: Column(
              children: [
                // Top spacing for larger screens
                if (!isSmallScreen) SizedBox(height: screenHeight * 0.05),
                
                // Content card
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: isSmallScreen ? 50.0 : 60.0,
                              color: Colors.blue,
                            ),
                            SizedBox(height: isSmallScreen ? 12.0 : 16.0),
                            Text(
                              'Create Your Account',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    style: const TextStyle(fontSize: 18),
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      labelStyle: const TextStyle(fontSize: 16),
                                      prefixIcon: const Icon(Icons.person, size: 24),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter first name';
                                      }
                                      final validation = InputValidator.validateName(value, fieldName: 'First name');
                                      return validation.isValid ? null : validation.message;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    style: const TextStyle(fontSize: 18),
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      labelStyle: const TextStyle(fontSize: 16),
                                      prefixIcon: const Icon(Icons.person_outline, size: 24),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(width: 2),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter last name';
                                      }
                                      final validation = InputValidator.validateName(value, fieldName: 'Last name');
                                      return validation.isValid ? null : validation.message;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                labelStyle: const TextStyle(fontSize: 16),
                                prefixIcon: const Icon(Icons.email, size: 24),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                final validation = InputValidator.validateEmail(value);
                                return validation.isValid ? null : validation.message;
                              },
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(fontSize: 18),
                              decoration: InputDecoration(
                                labelText: 'Phone Number (Optional)',
                                labelStyle: const TextStyle(fontSize: 16),
                                prefixIcon: const Icon(Icons.phone, size: 24),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final validation = InputValidator.validatePhoneNumber(value);
                                  return validation.isValid ? null : validation.message;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            EnhancedPasswordField(
                              controller: _passwordController,
                              labelText: 'Password',
                              hintText: 'Create a strong password',
                              showStrengthIndicator: true,
                              showRequirements: true,
                              onChanged: (password) {
                                setState(() {
                                  _currentPassword = password;
                                });
                              },
                            ),
                            const SizedBox(height: 20),
                            EnhancedPasswordField(
                              controller: _confirmPasswordController,
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              showStrengthIndicator: false,
                              showRequirements: false,
                              isConfirmPassword: true,
                              originalPassword: _currentPassword,
                            ),
                            const SizedBox(height: 24),
                            ExpansionTile(
                              title: const Text('Gym Information (Optional)', style: TextStyle(fontSize: 16)),
                              leading: const Icon(Icons.business, size: 24),
                              children: [
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _gymNameController,
                                  style: const TextStyle(fontSize: 18),
                                  decoration: InputDecoration(
                                    labelText: 'Gym Name',
                                    labelStyle: const TextStyle(fontSize: 16),
                                    prefixIcon: const Icon(Icons.fitness_center, size: 24),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _gymAddressController,
                                  maxLines: 2,
                                  style: const TextStyle(fontSize: 18),
                                  decoration: InputDecoration(
                                    labelText: 'Gym Address',
                                    labelStyle: const TextStyle(fontSize: 16),
                                    prefixIcon: const Icon(Icons.location_on, size: 24),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _gymDescriptionController,
                                  maxLines: 3,
                                  style: const TextStyle(fontSize: 18),
                                  decoration: InputDecoration(
                                    labelText: 'Gym Description',
                                    labelStyle: const TextStyle(fontSize: 16),
                                    prefixIcon: const Icon(Icons.description, size: 24),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(width: 2),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: Colors.grey.shade300, width: 2),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                  ),
                                ),
                              ],
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
                                    onPressed: authProvider.isLoading ? null : _register,
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
                                        : const Text('Register'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Bottom spacing for larger screens
                if (!isSmallScreen) SizedBox(height: screenHeight * 0.05),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        gymName: _gymNameController.text.trim().isEmpty ? null : _gymNameController.text.trim(),
        gymAddress: _gymAddressController.text.trim().isEmpty ? null : _gymAddressController.text.trim(),
        gymDescription: _gymDescriptionController.text.trim().isEmpty ? null : _gymDescriptionController.text.trim(),
      );

      if (success && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      }
    }
  }
}