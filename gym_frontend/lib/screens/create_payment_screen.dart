import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/payment_provider.dart';
import '../providers/member_provider.dart';
import '../providers/subscription_provider.dart';
import '../models/payment.dart';
import '../models/member.dart';
import '../models/member_subscription.dart';

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
  PaymentMethod _selectedMethod = PaymentMethod.cash;
  DateTime? _paymentDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _paymentDate = DateTime.now(); // Default to today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MemberProvider>(context, listen: false).fetchMembers();
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
      body: SingleChildScrollView(
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
                      if (_selectedMember != null)
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
            ],
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

      setState(() {
        _isLoading = true;
      });

      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      
      try {
        final success = await paymentProvider.createPayment(
          memberId: _selectedMember!.id!,
          subscriptionPlanId: _selectedSubscription?.subscriptionPlanId,
          amount: double.parse(_amountController.text),
          method: _selectedMethod,
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
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment recorded successfully!'),
              backgroundColor: Colors.green,
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
}