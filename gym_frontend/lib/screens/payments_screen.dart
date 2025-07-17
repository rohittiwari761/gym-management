import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/payment_provider.dart';
import '../providers/member_provider.dart';
import '../models/payment.dart';
import '../widgets/network_error_widget.dart';
import '../services/debug_api_service.dart';
import 'create_payment_screen.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      print('🔍 PAYMENTS_SCREEN: Starting debug tests...');
      
      // Run debug tests first
      final authTest = await DebugApiService.testAuthentication();
      print('🔍 PAYMENTS_SCREEN: Auth test result: $authTest');
      
      final paymentsTest = await DebugApiService.testPaymentsEndpoint();
      print('🔍 PAYMENTS_SCREEN: Payments test result: $paymentsTest');
      
      final revenueTest = await DebugApiService.testRevenueEndpoint();
      print('🔍 PAYMENTS_SCREEN: Revenue test result: $revenueTest');
      
      // Now run the normal provider calls
      final provider = Provider.of<PaymentProvider>(context, listen: false);
      provider.fetchPayments();
      provider.fetchRevenueAnalytics();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments & Revenue'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreatePaymentScreen(),
                ),
              );
              
              // Force refresh payments and members when returning from payment creation
              if (mounted) {
                Provider.of<PaymentProvider>(context, listen: false).fetchPayments();
                Provider.of<MemberProvider>(context, listen: false).fetchMembers(forceRefresh: true);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentsTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicatorColor: Theme.of(context).colorScheme.primary,
        indicatorWeight: 2.0,
        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(text: 'Payments'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        if (paymentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (paymentProvider.errorMessage != null) {
          return NetworkErrorWidget(
            errorMessage: paymentProvider.errorMessage,
            onRetry: () => paymentProvider.fetchPayments(),
            retryButtonText: 'Retry Loading Payments',
          );
        }

        final payments = paymentProvider.payments;

        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.payment, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No payments recorded yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreatePaymentScreen(),
                      ),
                    );
                    
                    // Force refresh payments and members when returning from payment creation
                    if (mounted) {
                      Provider.of<PaymentProvider>(context, listen: false).fetchPayments();
                      Provider.of<MemberProvider>(context, listen: false).fetchMembers(forceRefresh: true);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Record Payment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Quick Stats
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.1),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Today',
                      paymentProvider.todayPayments.length.toString(),
                      Icons.today,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'This Month',
                      '₹${paymentProvider.monthlyRevenue.toStringAsFixed(2)}',
                      Icons.calendar_month,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            // Payments List
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    paymentProvider.fetchPayments(),
                    paymentProvider.fetchRevenueAnalytics(),
                  ]);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return _buildPaymentCard(payment);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        if (paymentProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () async {
            await paymentProvider.fetchRevenueAnalytics();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Revenue Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildRevenueCard(
                    'Total Revenue',
                    '₹${paymentProvider.totalRevenue.toStringAsFixed(2)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                  _buildRevenueCard(
                    'Monthly Revenue',
                    '₹${paymentProvider.monthlyRevenue.toStringAsFixed(2)}',
                    Icons.calendar_month,
                    Colors.blue,
                  ),
                  _buildRevenueCard(
                    'Weekly Revenue',
                    '₹${paymentProvider.weeklyRevenue.toStringAsFixed(2)}',
                    Icons.date_range,
                    Colors.orange,
                  ),
                  _buildRevenueCard(
                    'Daily Revenue',
                    '₹${paymentProvider.dailyRevenue.toStringAsFixed(2)}',
                    Icons.today,
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Methods Distribution',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      // This would typically show a chart
                      // For now, showing a simple breakdown
                      ..._buildPaymentMethodBreakdown(paymentProvider.payments),
                    ],
                  ),
                ),
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(String title, String amount, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              amount,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Payment payment) {
    final memberName = payment.member?.user?.fullName ?? 'Unknown Member';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(payment.status),
          child: Icon(
            _getPaymentIcon(payment.method),
            color: Colors.white,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                payment.formattedAmount,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(payment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payment.statusDisplay,
                style: TextStyle(
                  color: _getStatusColor(payment.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    memberName,
                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.payment, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${payment.methodDisplay}'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(DateFormat('MMM dd, yyyy').format(payment.paymentDate)),
              ],
            ),
            if (payment.notes != null && payment.notes!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      payment.notes!,
                      style: TextStyle(color: Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  List<Widget> _buildPaymentMethodBreakdown(List<Payment> payments) {
    final methodCounts = <PaymentMethod, int>{};
    final methodAmounts = <PaymentMethod, double>{};

    for (final payment in payments) {
      if (payment.status == PaymentStatus.completed) {
        methodCounts[payment.method] = (methodCounts[payment.method] ?? 0) + 1;
        methodAmounts[payment.method] = (methodAmounts[payment.method] ?? 0) + payment.amount;
      }
    }

    if (methodCounts.isEmpty) {
      return [
        const Text('No payment data available'),
      ];
    }

    return methodCounts.entries.map((entry) {
      final method = entry.key;
      final count = entry.value;
      final amount = methodAmounts[method] ?? 0;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(_getPaymentIcon(method), size: 16),
                const SizedBox(width: 8),
                Text(_getPaymentMethodName(method)),
              ],
            ),
            Text(
              '$count payments • ₹${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }).toList();
  }

  Color _getStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.failed:
        return Colors.red;
      case PaymentStatus.refunded:
        return Colors.purple;
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