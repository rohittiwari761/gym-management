import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/payment_provider.dart';
import '../providers/member_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/payment.dart';
import '../models/member.dart';
import '../models/member_subscription.dart';
import '../models/subscription_plan.dart';

class CreatePaymentScreen extends StatefulWidget {
  const CreatePaymentScreen({super.key});

  @override
  State<CreatePaymentScreen> createState() => _CreatePaymentScreenState();
}

class _CreatePaymentScreenState extends State<CreatePaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();

  Member? _selectedMember;
  MemberSubscription? _selectedSubscription;
  SubscriptionPlan? _selectedSubscriptionPlan;
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime? _paymentDate;
  int _membershipMonths = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentDate = DateTime.now(); // Default to today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(context, listen: false).fetchMembers();
      Provider.of<SubscriptionProvider>(context, listen: false).fetchSubscriptionPlans();
      Provider.of<SubscriptionProvider>(context, listen: false).fetchMemberSubscriptions();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Member Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<MemberProvider>(
                        builder: (context, memberProvider, child) {
                          if (memberProvider.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final members = memberProvider.members;

                          return DropdownButtonFormField<Member>(
                            value: _selectedMember,
                            decoration: const InputDecoration(
                              labelText: 'Select Member',
                              border: OutlineInputBorder(),
                            ),
                            items: members.map((member) {
                              return DropdownMenuItem<Member>(
                                value: member,
                                child: Text(member.user?.fullName ?? 'Unknown Member'),
                              );
                            }).toList(),
                            onChanged: (member) {
                              setState(() {
                                _selectedMember = member;
                                _selectedSubscription = null;
                                _selectedSubscriptionPlan = null;
                                _amountController.clear();
                              });
                              _loadMemberSubscriptions();
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a member';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Current Member Status
                      if (_selectedMember != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getMemberStatusColor().withOpacity(0.1),
                            border: Border.all(color: _getMemberStatusColor()),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getMemberStatusIcon(),
                                    color: _getMemberStatusColor(),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Status',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getMemberStatusColor(),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Membership: ${_getMembershipStatus()}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              if (_selectedMember!.membershipExpiry != null)
                                Text(
                                  'Expires: ${DateFormat('MMM dd, yyyy').format(_selectedMember!.membershipExpiry!)}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              if (_getDaysUntilExpiry() != null)
                                Text(
                                  _getDaysUntilExpiry()!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: _getMemberStatusColor(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Subscription Plan Selection Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Subscription Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<SubscriptionProvider>(
                        builder: (context, subscriptionProvider, child) {
                          if (subscriptionProvider.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final plans = subscriptionProvider.activeSubscriptionPlans;

                          return DropdownButtonFormField<SubscriptionPlan>(
                            value: _selectedSubscriptionPlan,
                            decoration: const InputDecoration(
                              labelText: 'Select Subscription Plan',
                              border: OutlineInputBorder(),
                              helperText: 'Required: Choose a subscription plan for the payment',
                            ),
                            items: plans.map((plan) {
                                return DropdownMenuItem<SubscriptionPlan>(
                                  value: plan,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        plan.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '₹${plan.formattedPrice} - ${plan.formattedDuration}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            onChanged: (plan) {
                              setState(() {
                                _selectedSubscriptionPlan = plan;
                                if (plan != null) {
                                  _amountController.text = plan.price.toString();
                                  // Calculate months based on plan duration
                                  _membershipMonths = _calculateMonthsFromPlan(plan);
                                                              }
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
                      // Display-only membership duration from selected plan
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Membership Duration',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedSubscriptionPlan != null 
                                  ? '${_selectedSubscriptionPlan!.durationInMonths} months (${_selectedSubscriptionPlan!.formattedDuration})'
                                  : 'Select a plan to see duration',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Duration is automatically set by the selected subscription plan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Member Subscriptions Card
              if (_selectedMember != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Existing Subscriptions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Consumer<SubscriptionProvider>(
                          builder: (context, subscriptionProvider, child) {
                            final memberSubscriptions = subscriptionProvider.memberSubscriptions
                                .where((sub) => sub.memberId == _selectedMember!.id)
                                .toList();

                            if (memberSubscriptions.isEmpty) {
                              return const Text(
                                'No active subscriptions for this member',
                                style: TextStyle(color: Colors.grey),
                              );
                            }

                            return DropdownButtonFormField<MemberSubscription>(
                              value: _selectedSubscription,
                              decoration: const InputDecoration(
                                labelText: 'Related Subscription (Optional)',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<MemberSubscription>(
                                  value: null,
                                  child: Text('No specific subscription'),
                                ),
                                ...memberSubscriptions.map((subscription) {
                                  return DropdownMenuItem<MemberSubscription>(
                                    value: subscription,
                                    child: Text(
                                      subscription.subscriptionPlan?.name ?? 'Subscription',
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (subscription) {
                                setState(() {
                                  _selectedSubscription = subscription;
                                  if (subscription != null) {
                                    _amountController.text = subscription.amountPaid.toString();
                                  }
                                });
                              },
                            );
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
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _selectPaymentDate(),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Payment Date',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _paymentDate != null
                                ? DateFormat('MMM dd, yyyy').format(_paymentDate!)
                                : 'Select Payment Date',
                            style: TextStyle(
                              color: _paymentDate != null ? Colors.black : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PaymentMethod>(
                        value: _selectedMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                          border: OutlineInputBorder(),
                        ),
                        items: PaymentMethod.values.map((method) {
                          return DropdownMenuItem<PaymentMethod>(
                            value: method,
                            child: Row(
                              children: [
                                Icon(_getPaymentIcon(method)),
                                const SizedBox(width: 8),
                                Text(_getPaymentMethodName(method)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (method) {
                          setState(() {
                            _selectedMethod = method!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedMethod != PaymentMethod.cash)
                        TextFormField(
                          controller: _transactionIdController,
                          decoration: const InputDecoration(
                            labelText: 'Transaction ID (Optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (Optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _recordPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Record Payment'),
                ),
              ),
              const SizedBox(height: 32), // Extra padding at bottom
            ],
            ),
          ),
        ),
      ),
    );
  }

  void _loadMemberSubscriptions() {
    if (_selectedMember != null) {
      Provider.of<SubscriptionProvider>(context, listen: false)
          .fetchMemberSubscriptions();
    }
  }

  Future<void> _recordPayment() async {
    if (_formKey.currentState!.validate()) {
      // Validate that member has an ID
      if (_selectedMember?.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected member does not have a valid ID. Please select a different member.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Validate that a subscription plan is selected
      if (_selectedSubscriptionPlan == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a subscription plan for this payment.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      
      try {
        final success = await paymentProvider.createPayment(
          memberId: _selectedMember!.id!,
          subscriptionPlanId: _selectedSubscriptionPlan?.id,
          amount: double.parse(_amountController.text),
          method: _selectedMethod,
          membershipMonths: _membershipMonths,
          transactionId: _transactionIdController.text.trim().isEmpty 
              ? null 
              : _transactionIdController.text.trim(),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          paymentDate: _paymentDate,
        );

        setState(() {
          _isLoading = false;
        });

        if (success && mounted) {
          // First, refresh member data to get updated information from backend
          print('💳 UI: Force refreshing member data after payment...');
          await Provider.of<MemberProvider>(context, listen: false).fetchMembers(forceRefresh: true);
          
          // Update the selected member with fresh data from the backend
          if (_selectedMember != null) {
            final memberProvider = Provider.of<MemberProvider>(context, listen: false);
            final updatedMember = memberProvider.members.firstWhere(
              (m) => m.id == _selectedMember!.id,
              orElse: () => _selectedMember!,
            );
            
            print('💳 UI: Member expiry updated from ${_selectedMember!.membershipExpiry} to ${updatedMember.membershipExpiry}');
            
            setState(() {
              _selectedMember = updatedMember;
            });
            
            // Give UI time to update before showing success message
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully! Membership extended.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(paymentProvider.errorMessage ?? 'Failed to record payment'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _selectPaymentDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paymentDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // 1 year ago
      lastDate: DateTime.now(), // Can't select future dates
    );

    if (date != null) {
      setState(() {
        _paymentDate = date;
      });
    }
  }

  IconData _getPaymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.card:
        return Icons.credit_card;
      case PaymentMethod.upi:
        return Icons.qr_code_scanner;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance;
    }
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }

  int _calculateMonthsFromPlan(SubscriptionPlan plan) {
    // The SubscriptionPlan model already has durationInMonths
    return plan.durationInMonths;
  }


  // Member status helper methods
  Color _getMemberStatusColor() {
    if (_selectedMember == null) return Colors.grey;
    
    final now = DateTime.now();
    final expiry = _selectedMember!.membershipExpiry;
    
    if (expiry == null) return Colors.grey;
    
    if (!_selectedMember!.isActive) {
      return Colors.red;
    }
    
    if (expiry.isBefore(now)) {
      return Colors.red;
    }
    
    final daysUntilExpiry = expiry.difference(now).inDays;
    if (daysUntilExpiry <= 7) {
      return Colors.orange;
    }
    
    return Colors.green;
  }
  
  IconData _getMemberStatusIcon() {
    if (_selectedMember == null) return Icons.help_outline;
    
    final now = DateTime.now();
    final expiry = _selectedMember!.membershipExpiry;
    
    if (expiry == null) return Icons.help_outline;
    
    if (!_selectedMember!.isActive) {
      return Icons.block;
    }
    
    if (expiry.isBefore(now)) {
      return Icons.error;
    }
    
    final daysUntilExpiry = expiry.difference(now).inDays;
    if (daysUntilExpiry <= 7) {
      return Icons.warning;
    }
    
    return Icons.check_circle;
  }
  
  String _getMembershipStatus() {
    if (_selectedMember == null) return 'No member selected';
    
    final now = DateTime.now();
    final expiry = _selectedMember!.membershipExpiry;
    
    if (expiry == null) return 'No expiry date set';
    
    if (!_selectedMember!.isActive) {
      return 'Inactive';
    }
    
    if (expiry.isBefore(now)) {
      return 'Expired';
    }
    
    final daysUntilExpiry = expiry.difference(now).inDays;
    if (daysUntilExpiry <= 7) {
      return 'Expiring Soon';
    }
    
    return 'Active';
  }
  
  String? _getDaysUntilExpiry() {
    if (_selectedMember == null || _selectedMember!.membershipExpiry == null) {
      return null;
    }
    
    final now = DateTime.now();
    final expiry = _selectedMember!.membershipExpiry!;
    
    if (expiry.isBefore(now)) {
      final daysExpired = now.difference(expiry).inDays;
      return 'Expired $daysExpired day${daysExpired != 1 ? 's' : ''} ago';
    }
    
    final daysUntilExpiry = expiry.difference(now).inDays;
    if (daysUntilExpiry == 0) {
      return 'Expires today';
    } else if (daysUntilExpiry == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in $daysUntilExpiry days';
    }
  }
}