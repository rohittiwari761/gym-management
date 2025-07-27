import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../providers/trainer_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_utils.dart';
import 'responsive_layout.dart';

class EnhancedDashboard extends StatelessWidget {
  const EnhancedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Container(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 32),
                  _buildQuickStats(context),
                  const SizedBox(height: 32),
                  _buildRevenueSection(context),
                  const SizedBox(height: 32),
                  _buildRecentActivity(context),
                  const SizedBox(height: 32),
                  _buildQuickActions(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.currentUser;
        final userName = user != null ? '${user.firstName} ${user.lastName}' : 'Guest';
        final gymName = user?.gymName ?? 'Gym Management System';
        
        return Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $userName!',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.isDesktop(context) ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    gymName,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.isDesktop(context) ? 18 : 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dashboard Overview • ${DateTime.now().toString().split(' ')[0]}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (ResponsiveUtils.isDesktop(context))
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      'All Systems Online',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    final crossAxisCount = isDesktop ? 4 : 2;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Overview',
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: isDesktop ? 300 : 200,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.4 : 1.2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Consumer<MemberProvider>(
              builder: (context, memberProvider, child) {
                return _buildEnhancedStatCard(
                  context,
                  'Total Members',
                  '${memberProvider.members.length}',
                  Icons.people,
                  Colors.blue,
                  '+${memberProvider.members.where((m) => m.joinDate != null && m.joinDate!.isAfter(DateTime.now().subtract(const Duration(days: 30)))).length} this month',
                );
              },
            ),
            Consumer<MemberProvider>(
              builder: (context, memberProvider, child) {
                final activeMembers = memberProvider.members.where((m) => m.isActive).length;
                final totalMembers = memberProvider.members.length;
                final percentage = totalMembers > 0 ? (activeMembers / totalMembers * 100).toStringAsFixed(1) : '0';
                
                return _buildEnhancedStatCard(
                  context,
                  'Active Members',
                  '$activeMembers',
                  Icons.person_add,
                  Colors.green,
                  '$percentage% of total',
                );
              },
            ),
            Consumer<TrainerProvider>(
              builder: (context, trainerProvider, child) {
                return _buildEnhancedStatCard(
                  context,
                  'Trainers',
                  '${trainerProvider.trainers.length}',
                  Icons.fitness_center,
                  Colors.orange,
                  'Professional staff',
                );
              },
            ),
            Consumer<EquipmentProvider>(
              builder: (context, equipmentProvider, child) {
                final workingEquipment = equipmentProvider.equipment.where((e) => e.isWorking).length;
                final totalEquipment = equipmentProvider.equipment.length;
                final percentage = totalEquipment > 0 ? (workingEquipment / totalEquipment * 100).toStringAsFixed(1) : '0';
                
                return _buildEnhancedStatCard(
                  context,
                  'Working Equipment',
                  '$workingEquipment',
                  Icons.sports_gymnastics,
                  Colors.purple,
                  '$percentage% operational',
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueSection(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue Analytics',
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Consumer<PaymentProvider>(
          builder: (context, paymentProvider, child) {
            return GridView(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: isDesktop ? 250 : 180,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isDesktop ? 1.6 : 1.2,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildRevenueCard(
                  context,
                  'Monthly Revenue',
                  '₹${paymentProvider.monthlyRevenue.toStringAsFixed(0)}',
                  Icons.calendar_month,
                  Colors.green,
                  'Current month',
                ),
                _buildRevenueCard(
                  context,
                  'Today\'s Revenue',
                  '₹${paymentProvider.dailyRevenue.toStringAsFixed(0)}',
                  Icons.today,
                  Colors.blue,
                  'Today\'s earnings',
                ),
                _buildRevenueCard(
                  context,
                  'Total Revenue',
                  '₹${paymentProvider.totalRevenue.toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.purple,
                  'All time',
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final activities = [
                {'icon': Icons.person_add, 'title': 'New member registered', 'time': '2 hours ago', 'color': Colors.green},
                {'icon': Icons.payment, 'title': 'Payment received', 'time': '4 hours ago', 'color': Colors.blue},
                {'icon': Icons.fitness_center, 'title': 'Equipment maintenance', 'time': '1 day ago', 'color': Colors.orange},
                {'icon': Icons.schedule, 'title': 'Class schedule updated', 'time': '2 days ago', 'color': Colors.purple},
                {'icon': Icons.trending_up, 'title': 'Monthly report generated', 'time': '3 days ago', 'color': Colors.teal},
              ];
              
              final activity = activities[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: (activity['color'] as Color).withOpacity(0.1),
                  child: Icon(
                    activity['icon'] as IconData,
                    color: activity['color'] as Color,
                  ),
                ),
                title: Text(
                  activity['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(activity['time'] as String),
                trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final isDesktop = ResponsiveUtils.isDesktop(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isDesktop ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isDesktop ? 2.5 : 2.0,
          children: [
            _buildActionCard(
              context,
              'Add Member',
              Icons.person_add,
              Colors.blue,
              () {
                // Navigate to add member
              },
            ),
            _buildActionCard(
              context,
              'Record Payment',
              Icons.payment,
              Colors.green,
              () {
                // Navigate to record payment
              },
            ),
            _buildActionCard(
              context,
              'Mark Attendance',
              Icons.checklist,
              Colors.orange,
              () {
                // Navigate to attendance
              },
            ),
            _buildActionCard(
              context,
              'Generate Report',
              Icons.assessment,
              Colors.purple,
              () {
                // Generate report
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return EnhancedCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.trending_up, color: Colors.green.shade600, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: ResponsiveUtils.isDesktop(context) ? 32 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const Spacer(),
              Icon(Icons.more_vert, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amount,
            style: TextStyle(
              fontSize: ResponsiveUtils.isDesktop(context) ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return EnhancedCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
        ],
      ),
    );
  }
}