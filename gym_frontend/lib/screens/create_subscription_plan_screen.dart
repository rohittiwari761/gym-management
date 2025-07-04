import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription_plan.dart';

class CreateSubscriptionPlanScreen extends StatefulWidget {
  final SubscriptionPlan? planToEdit;

  const CreateSubscriptionPlanScreen({super.key, this.planToEdit});

  @override
  State<CreateSubscriptionPlanScreen> createState() => _CreateSubscriptionPlanScreenState();
}

class _CreateSubscriptionPlanScreenState extends State<CreateSubscriptionPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _discountController = TextEditingController();
  final _featureController = TextEditingController();
  
  List<String> _features = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.planToEdit != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final plan = widget.planToEdit!;
    _nameController.text = plan.name;
    _descriptionController.text = plan.description;
    _priceController.text = plan.price.toString();
    _durationController.text = plan.durationInMonths.toString();
    _discountController.text = plan.discountPercentage ?? '';
    _features = List.from(plan.features);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _discountController.dispose();
    _featureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.planToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Subscription Plan' : 'Create Subscription Plan'),
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
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Plan Name',
                          hintText: 'e.g., Premium Membership',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a plan name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe what this plan includes...',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
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
                        'Pricing & Duration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price (₹)',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a price';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duration (Months)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter duration';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Please enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Discount Percentage (Optional)',
                          suffixText: '%',
                          border: OutlineInputBorder(),
                        ),
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
                        'Features',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _featureController,
                              decoration: const InputDecoration(
                                labelText: 'Add Feature',
                                hintText: 'e.g., Access to all equipment',
                                border: OutlineInputBorder(),
                              ),
                              onFieldSubmitted: _addFeature,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _addFeature(_featureController.text),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_features.isNotEmpty) ...[
                        const Text(
                          'Current Features:',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        ..._features.asMap().entries.map((entry) {
                          final index = entry.key;
                          final feature = entry.value;
                          return Card(
                            color: Colors.blue.withOpacity(0.1),
                            child: ListTile(
                              leading: const Icon(Icons.check_circle, color: Colors.green),
                              title: Text(feature),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeFeature(index),
                              ),
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _savePlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEditing ? 'Update Plan' : 'Create Plan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addFeature(String feature) {
    if (feature.trim().isNotEmpty && !_features.contains(feature.trim())) {
      if (mounted) {
        setState(() {
          _features.add(feature.trim());
          _featureController.clear();
        });
      }
    }
  }

  void _removeFeature(int index) {
    if (mounted) {
      setState(() {
        _features.removeAt(index);
      });
    }
  }

  Future<void> _savePlan() async {
    if (_formKey.currentState!.validate()) {
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
      bool success = false;

      if (widget.planToEdit != null) {
        success = await subscriptionProvider.updateSubscriptionPlan(
          widget.planToEdit!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          durationInMonths: int.parse(_durationController.text),
          features: _features,
          discountPercentage: _discountController.text.trim().isEmpty 
              ? null 
              : _discountController.text.trim(),
        );
      } else {
        success = await subscriptionProvider.createSubscriptionPlan(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          durationInMonths: int.parse(_durationController.text),
          features: _features,
          discountPercentage: _discountController.text.trim().isEmpty 
              ? null 
              : _discountController.text.trim(),
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      if (success && mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.planToEdit != null 
                  ? 'Subscription plan updated successfully!'
                  : 'Subscription plan created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(subscriptionProvider.errorMessage ?? 'Failed to save plan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}