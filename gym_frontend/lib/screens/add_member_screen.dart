import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/member_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_plan.dart';
import '../models/member.dart';
import '../security/input_validator.dart';
import '../security/security_config.dart';

class AddMemberScreen extends StatefulWidget {
  final Member? memberToEdit;
  
  const AddMemberScreen({super.key, this.memberToEdit});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Personal Information
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String _gender = 'Male';

  // Emergency Contact
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationController = TextEditingController();

  // Address
  final _addressController = TextEditingController();

  // Physical Attributes (New)
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Membership Details
  SubscriptionPlan? _selectedPlan;
  DateTime? _joinDate;
  String _membershipType = 'basic';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _joinDate = DateTime.now();
    
    // Add listeners for BMI calculation
    _heightController.addListener(_updateBMI);
    _weightController.addListener(_updateBMI);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionProvider>(context, listen: false).fetchSubscriptionPlans();
    });
  }
  
  void _updateBMI() {
    setState(() {
      // Trigger rebuild to update BMI preview
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationController.dispose();
    _addressController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Member'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildStepIndicator(0, 'Personal'),
                _buildStepConnector(),
                _buildStepIndicator(1, 'Contact'),
                _buildStepConnector(),
                _buildStepIndicator(2, 'Physical'),
                _buildStepConnector(),
                _buildStepIndicator(3, 'Membership'),
              ],
            ),
          ),
          // Form Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                _buildPersonalInfoStep(),
                _buildContactInfoStep(),
                _buildPhysicalAttributesStep(),
                _buildMembershipStep(),
              ],
            ),
          ),
          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_currentStep == 3 ? 'Add Member' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = step <= _currentStep;
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector() {
    return Expanded(
      child: Container(
        height: 2,
        color: Colors.grey[300],
        margin: const EdgeInsets.only(bottom: 24),
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
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
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    final validation = InputValidator.validateEmail(value);
                    return validation.isValid ? null : validation.message;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    final validation = InputValidator.validatePhoneNumber(value);
                    return validation.isValid ? null : validation.message;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () => _selectDateOfBirth(),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _dateOfBirth != null
                          ? DateFormat('MMM dd, yyyy').format(_dateOfBirth!)
                          : 'Select Date of Birth',
                      style: TextStyle(
                        color: _dateOfBirth != null ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Male', 'Female', 'Other'].map((gender) {
                    return DropdownMenuItem<String>(
                      value: gender,
                      child: Text(gender),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _gender = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency Contact',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter emergency contact name';
                      }
                      final validation = InputValidator.validateName(value, fieldName: 'Emergency contact name');
                      return validation.isValid ? null : validation.message;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emergencyPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Phone',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter emergency contact phone';
                      }
                      final validation = InputValidator.validatePhoneNumber(value);
                      return validation.isValid ? null : validation.message;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emergencyRelationController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship',
                      hintText: 'e.g., Parent, Spouse, Friend',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter relationship';
                      }
                      final validation = InputValidator.validateTextInput(
                        value,
                        maxLength: 50,
                        fieldName: 'Relationship',
                      );
                      return validation.isValid ? null : validation.message;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Home Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final validation = InputValidator.validateTextInput(
                          value,
                          maxLength: 200,
                          fieldName: 'Address',
                          allowEmpty: true,
                        );
                        return validation.isValid ? null : validation.message;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalAttributesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Physical Attributes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Help us track fitness progress (Optional)',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Height (cm)',
                            border: OutlineInputBorder(),
                            suffixText: 'cm',
                            hintText: '170',
                            prefixIcon: Icon(Icons.height),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final height = double.tryParse(value);
                              if (height == null) {
                                return 'Please enter a valid height';
                              }
                              if (height < 50 || height > 300) {
                                return 'Height must be between 50-300 cm';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(),
                            suffixText: 'kg',
                            hintText: '70',
                            prefixIcon: Icon(Icons.monitor_weight),
                          ),
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final weight = double.tryParse(value);
                              if (weight == null) {
                                return 'Please enter a valid weight';
                              }
                              if (weight < 20 || weight > 500) {
                                return 'Weight must be between 20-500 kg';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // BMI Preview
                  if (_heightController.text.isNotEmpty && _weightController.text.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calculate, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'BMI Preview',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildBMIPreview(),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Note: BMI will be automatically calculated and can help track fitness progress over time.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMIPreview() {
    final heightStr = _heightController.text;
    final weightStr = _weightController.text;
    
    if (heightStr.isEmpty || weightStr.isEmpty) {
      return const Text('Enter height and weight to see BMI');
    }
    
    final height = double.tryParse(heightStr);
    final weight = double.tryParse(weightStr);
    
    if (height == null || weight == null || height <= 0) {
      return const Text('Invalid height or weight');
    }
    
    final heightM = height / 100;
    final bmi = weight / (heightM * heightM);
    
    String category;
    Color categoryColor;
    
    if (bmi < 18.5) {
      category = 'Underweight';
      categoryColor = Colors.blue;
    } else if (bmi < 25) {
      category = 'Normal weight';
      categoryColor = Colors.green;
    } else if (bmi < 30) {
      category = 'Overweight';
      categoryColor = Colors.orange;
    } else {
      category = 'Obese';
      categoryColor = Colors.red;
    }
    
    return Column(
      children: [
        Text(
          'BMI: ${bmi.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: categoryColor),
          ),
          child: Text(
            category,
            style: TextStyle(
              color: categoryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMembershipStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Membership Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Consumer<SubscriptionProvider>(
                builder: (context, subscriptionProvider, child) {
                  final plans = subscriptionProvider.activeSubscriptionPlans;

                  if (plans.isEmpty) {
                    return const Text(
                      'No subscription plans available. Please create plans first.',
                      style: TextStyle(color: Colors.red),
                    );
                  }

                  return DropdownButtonFormField<SubscriptionPlan>(
                    value: _selectedPlan,
                    decoration: const InputDecoration(
                      labelText: 'Subscription Plan',
                      border: OutlineInputBorder(),
                    ),
                    items: plans.map((plan) {
                      return DropdownMenuItem<SubscriptionPlan>(
                        value: plan,
                        child: Text('${plan.name} - ${plan.formattedPrice}'),
                      );
                    }).toList(),
                    onChanged: (plan) {
                      setState(() {
                        _selectedPlan = plan;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a subscription plan';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectJoinDate(),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Join Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _joinDate != null
                        ? DateFormat('MMM dd, yyyy').format(_joinDate!)
                        : 'Select Join Date',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Membership Type Dropdown
              DropdownButtonFormField<String>(
                value: _membershipType,
                decoration: const InputDecoration(
                  labelText: 'Membership Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'basic', child: Text('Basic')),
                  DropdownMenuItem(value: 'premium', child: Text('Premium')),
                  DropdownMenuItem(value: 'vip', child: Text('VIP')),
                ],
                onChanged: (value) {
                  setState(() {
                    _membershipType = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a membership type';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),
              if (_selectedPlan != null) ...[
                const Text(
                  'Plan Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...(_selectedPlan!.features.map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(feature)),
                    ],
                  ),
                ))),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedPlan!.formattedPrice,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Add extra bottom padding to prevent overflow
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
      firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _dateOfBirth = date;
      });
    }
  }

  Future<void> _selectJoinDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _joinDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      setState(() {
        _joinDate = date;
      });
    }
  }

  void _handleNext() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate() && _dateOfBirth != null) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        if (_dateOfBirth == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select date of birth'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else if (_currentStep == 1) {
      if (_emergencyNameController.text.isNotEmpty &&
          _emergencyPhoneController.text.isNotEmpty &&
          _emergencyRelationController.text.isNotEmpty) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill in emergency contact information'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (_currentStep == 2) {
      // Physical attributes step - validation is optional but check format if provided
      if (_formKey.currentState!.validate()) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _addMember();
    }
  }

  Future<void> _addMember() async {
    if (_selectedPlan == null || _joinDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all membership details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    
    // Sanitize all inputs before creating member
    final sanitizedFirstName = InputValidator.sanitizeInput(_firstNameController.text.trim());
    final sanitizedLastName = InputValidator.sanitizeInput(_lastNameController.text.trim());
    final sanitizedEmail = InputValidator.sanitizeInput(_emailController.text.trim());
    final sanitizedPhone = InputValidator.sanitizeInput(_phoneController.text.trim());
    final sanitizedEmergencyName = InputValidator.sanitizeInput(_emergencyNameController.text.trim());
    final sanitizedEmergencyPhone = InputValidator.sanitizeInput(_emergencyPhoneController.text.trim());
    final sanitizedEmergencyRelation = InputValidator.sanitizeInput(_emergencyRelationController.text.trim());
    final sanitizedAddress = InputValidator.sanitizeInput(_addressController.text.trim());

    SecurityConfig.logSecurityEvent('MEMBER_CREATION_ATTEMPT', {
      'email': sanitizedEmail,
      'membershipType': _membershipType,
    });

    // Parse height and weight if provided
    double? heightCm;
    double? weightKg;
    
    if (_heightController.text.isNotEmpty) {
      heightCm = double.tryParse(_heightController.text.trim());
    }
    
    if (_weightController.text.isNotEmpty) {
      weightKg = double.tryParse(_weightController.text.trim());
    }

    final success = await memberProvider.createMember(
      firstName: sanitizedFirstName,
      lastName: sanitizedLastName,
      email: sanitizedEmail,
      phoneNumber: sanitizedPhone,
      dateOfBirth: _dateOfBirth!,
      gender: _gender,
      emergencyContactName: sanitizedEmergencyName,
      emergencyContactPhone: sanitizedEmergencyPhone,
      emergencyContactRelation: sanitizedEmergencyRelation,
      address: sanitizedAddress,
      membershipType: _membershipType,
      joinDate: _joinDate!,
      subscriptionPlanId: _selectedPlan!.id,
      heightCm: heightCm,
      weightKg: weightKg,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Member added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(memberProvider.errorMessage ?? 'Failed to add member'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}