import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../models/member_subscription.dart';

class RenewalsScreen extends StatefulWidget {
  const RenewalsScreen({super.key});

  @override
  State<RenewalsScreen> createState() => _RenewalsScreenState();
}

class _RenewalsScreenState extends State<RenewalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SubscriptionProvider>(context, listen: false).fetchMemberSubscriptions();
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
        title: const Text('Subscription Renewals'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          if (subscriptionProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (subscriptionProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    subscriptionProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => subscriptionProvider.fetchMemberSubscriptions(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildExpiringTab(subscriptionProvider.expiringSubscriptions),
              _buildExpiredTab(subscriptionProvider.expiredSubscriptions),
              _buildAllSubscriptionsTab(subscriptionProvider.memberSubscriptions),
            ],
          );
        },
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
        labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Expiring'),
          Tab(text: 'Expired'),
          Tab(text: 'All'),
        ],
      ),
    );
  }

  Widget _buildExpiringTab(List<MemberSubscription> expiringSubscriptions) {
    if (expiringSubscriptions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No subscriptions expiring soon',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<SubscriptionProvider>(context, listen: false)
            .fetchMemberSubscriptions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expiringSubscriptions.length,
        itemBuilder: (context, index) {
          final subscription = expiringSubscriptions[index];
          return _buildSubscriptionCard(subscription, Colors.orange);
        },
      ),
    );
  }

  Widget _buildExpiredTab(List<MemberSubscription> expiredSubscriptions) {
    if (expiredSubscriptions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'No expired subscriptions',
              style: TextStyle(fontSize: 18, color: Colors.green),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<SubscriptionProvider>(context, listen: false)
            .fetchMemberSubscriptions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: expiredSubscriptions.length,
        itemBuilder: (context, index) {
          final subscription = expiredSubscriptions[index];
          return _buildSubscriptionCard(subscription, Colors.red);
        },
      ),
    );
  }

  Widget _buildAllSubscriptionsTab(List<MemberSubscription> subscriptions) {
    if (subscriptions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subscriptions, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No subscriptions found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<SubscriptionProvider>(context, listen: false)
            .fetchMemberSubscriptions();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: subscriptions.length,
        itemBuilder: (context, index) {
          final subscription = subscriptions[index];
          Color cardColor = Colors.blue;
          
          if (subscription.isExpired) {
            cardColor = Colors.red;
          } else if (subscription.isExpiringSoon) {
            cardColor = Colors.orange;
          } else if (subscription.isActive) {
            cardColor = Colors.green;
          }

          return _buildSubscriptionCard(subscription, cardColor);
        },
      ),
    );
  }

  Widget _buildSubscriptionCard(MemberSubscription subscription, Color accentColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.member?.user?.fullName ?? 'Unknown Member',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.subscriptionPlan?.name ?? 'Unknown Plan',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor),
                  ),
                  child: Text(
                    subscription.statusDisplay,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Start Date',
                    DateFormat('MMM dd, yyyy').format(subscription.startDate),
                    Icons.play_arrow,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'End Date',
                    DateFormat('MMM dd, yyyy').format(subscription.endDate),
                    Icons.stop,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Amount',
                    subscription.formattedAmount,
                    Icons.money,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Days Until Expiry',
                    subscription.daysUntilExpiry.toString(),
                    Icons.calendar_today,
                  ),
                ),
              ],
            ),
            if (subscription.isExpired || subscription.isExpiringSoon) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showRenewalDialog(subscription),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Renew'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showContactDialog(subscription),
                      icon: const Icon(Icons.contact_phone),
                      label: const Text('Contact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showRenewalDialog(MemberSubscription subscription) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renew Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Member: ${subscription.member?.user?.fullName}'),
            Text('Plan: ${subscription.subscriptionPlan?.name}'),
            Text('Amount: ${subscription.formattedAmount}'),
            const SizedBox(height: 16),
            const Text('This will extend the subscription for another period.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = Provider.of<SubscriptionProvider>(context, listen: false);
              final success = await provider.renewSubscription(
                subscription.id,
                amountPaid: subscription.amountPaid,
                paymentMethod: 'cash',
                notes: 'Renewed subscription',
              );
              
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Subscription renewed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Renew'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog(MemberSubscription subscription) {
    final member = subscription.member;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(member?.user?.fullName ?? 'Unknown'),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: Text(member?.user?.email ?? 'No email'),
              contentPadding: EdgeInsets.zero,
            ),
            if (member?.phoneNumber != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(member!.phoneNumber),
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}