import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/member_provider.dart';
import '../models/member.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart' as common_widgets;
import '../widgets/optimized_widgets.dart';
import 'add_member_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MemberProvider? _memberProvider;
  ScaffoldMessengerState? _scaffoldMessenger;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely get the provider and scaffold messenger references during dependency changes
    _memberProvider = Provider.of<MemberProvider>(context, listen: false);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _memberProvider = null;
    _scaffoldMessenger = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _navigateToAddMember(context),
            icon: const Icon(Icons.person_add, size: 20),
            tooltip: 'Add Member',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMemberStats(context),
          _buildSearchBar(context),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMembersList(context, null), // All members
                _buildMembersList(context, true), // Active only
                _buildMembersList(context, false), // Inactive only
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Consumer<MemberProvider>(
        builder: (context, provider, child) {
          final activeMembers = provider.activeMembers.length;
          final inactiveMembers = provider.members.length - activeMembers;
          
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Members',
                  '${provider.members.length}',
                  Icons.people,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Active',
                  '$activeMembers',
                  Icons.person,
                  Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatCard(
                  'Inactive',
                  '$inactiveMembers',
                  Icons.person_off,
                  Colors.orange,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return common_widgets.SearchBar(
      hintText: 'Search members by name, phone, or email...',
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
      onClear: () {
        _searchController.clear();
        setState(() {
          _searchQuery = '';
        });
      },
    );
  }

  Widget _buildTabBar(BuildContext context) {
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
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        isScrollable: context.isMobile,
        tabAlignment: context.isMobile ? TabAlignment.start : TabAlignment.fill,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Active'),
          Tab(text: 'Inactive'),
        ],
      ),
    );
  }

  Widget _buildMembersList(BuildContext context, bool? activeFilter) {
    return Consumer<MemberProvider>(
      builder: (context, memberProvider, child) {
        if (memberProvider.isLoading) {
          return const common_widgets.LoadingWidget(message: 'Loading members...');
        }

        if (memberProvider.errorMessage?.isNotEmpty == true) {
          return common_widgets.ErrorWidget(
            title: 'Failed to load members',
            message: memberProvider.errorMessage,
            actionText: 'Retry',
            onAction: () => memberProvider.fetchMembers(),
          );
        }

        List<Member> filteredMembers = _getFilteredMembers(memberProvider.members, activeFilter);

        if (filteredMembers.isEmpty) {
          return common_widgets.EmptyStateWidget(
            icon: Icons.people_outline,
            title: _getEmptyTitle(activeFilter),
            subtitle: _getEmptySubtitle(activeFilter),
            actionText: 'Add Member',
            onAction: () => _navigateToAddMember(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () => memberProvider.fetchMembers(),
          child: context.isDesktop
              ? _buildGridView(context, filteredMembers)
              : _buildListView(context, filteredMembers),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, List<Member> members) {
    return ListView.builder(
      padding: context.screenPadding,
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberCard(context, member);
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<Member> members) {
    return GridView.builder(
      padding: context.screenPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        childAspectRatio: 1.2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberCard(context, member);
      },
    );
  }

  Widget _buildMemberCard(BuildContext context, Member member) {
    // Check if member matches search query
    if (_searchQuery.isNotEmpty && !_matchesSearchQuery(member)) {
      return const SizedBox.shrink();
    }

    return common_widgets.ResponsiveCard(
      margin: EdgeInsets.only(bottom: AppSpacing.sm),
      onTap: () => _showMemberDetails(context, member),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: context.isMobile ? 50 : 60,
                height: context.isMobile ? 50 : 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: member.isActive ? AppTheme.successGradient : 
                    LinearGradient(
                      colors: [AppTheme.errorRed.withValues(alpha: 0.8), AppTheme.errorRed],
                    ),
                ),
                child: Center(
                  child: Text(
                    member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M',
                    style: AppTextStyles.heading3(context).copyWith(
                      color: Colors.white,
                      fontSize: context.isMobile ? 18 : 24,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle1(context),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    _buildInfoRow(
                      context,
                      Icons.phone,
                      member.phone,
                    ),
                    if (!context.isMobile) ...[
                      SizedBox(height: AppSpacing.xs),
                      _buildInfoRow(
                        context,
                        Icons.email,
                        member.user?.email ?? 'No email',
                      ),
                    ],
                    SizedBox(height: AppSpacing.xs),
                    _buildInfoRow(
                      context,
                      Icons.card_membership,
                      member.membershipType.toUpperCase(),
                    ),
                    // Emergency contact info
                    if (member.emergencyContactName != null && member.emergencyContactName!.isNotEmpty) ...[
                      SizedBox(height: AppSpacing.xs),
                      _buildInfoRow(
                        context,
                        Icons.contact_emergency,
                        'Emergency: ${member.emergencyContactName}',
                        isSecondary: true,
                      ),
                      if (member.emergencyContactPhone != null && member.emergencyContactPhone!.isNotEmpty) ...[
                        SizedBox(height: AppSpacing.xs),
                        _buildInfoRow(
                          context,
                          Icons.phone_callback,
                          '${member.emergencyContactPhone}',
                          isSecondary: true,
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              
              // Status Badge
              common_widgets.StatusBadge(
                status: member.isActive ? 'active' : 'inactive',
              ),
            ],
          ),
          
          if (context.isMobile) ...[
            SizedBox(height: AppSpacing.sm),
            _buildInfoRow(
              context,
              Icons.email,
              member.user?.email ?? 'No email',
            ),
          ],
          
          SizedBox(height: AppSpacing.md),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: common_widgets.ResponsiveButton(
                  text: 'View Details',
                  icon: Icons.visibility,
                  type: common_widgets.ButtonType.outlined,
                  onPressed: () => _showMemberDetails(context, member),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              common_widgets.ResponsiveButton(
                text: member.isActive ? 'Deactivate' : 'Activate',
                icon: member.isActive ? Icons.pause : Icons.play_arrow,
                type: common_widgets.ButtonType.text,
                color: member.isActive ? AppTheme.warningOrange : AppTheme.successGreen,
                onPressed: () => _toggleMemberStatusDirect(context, member),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text, {bool isSecondary = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: context.smallIconSize,
          color: isSecondary ? AppTheme.textSecondary(context).withOpacity(0.7) : AppTheme.textSecondary(context),
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: isSecondary 
                ? AppTextStyles.body2(context).copyWith(
                    fontSize: 12,
                    color: AppTheme.textSecondary(context).withOpacity(0.8),
                  )
                : AppTextStyles.body2(context),
          ),
        ),
      ],
    );
  }

  void _toggleMemberStatusDirect(BuildContext context, Member member) async {
    // Check if widget is still mounted and provider is available
    if (!mounted || _memberProvider == null || _scaffoldMessenger == null) {
      return;
    }
    
    if (member.id == null) {
      _scaffoldMessenger!.showSnackBar(
        const SnackBar(
          content: Text('Invalid member ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final success = await _memberProvider!.updateMemberStatus(member.id!, !member.isActive);
      
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? 'Member ${!member.isActive ? 'activated' : 'deactivated'} successfully'
                : 'Failed to update member status',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          const SnackBar(
            content: Text('Error updating member status'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _toggleMemberStatus(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member.isActive ? 'Deactivate' : 'Activate'} Member'),
        content: Text(
          'Are you sure you want to ${member.isActive ? 'deactivate' : 'activate'} ${member.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              _toggleMemberStatusDirect(context, member);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: member.isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(member.isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _showMemberDetails(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: member.isActive 
                          ? [Colors.green.shade400, Colors.green.shade600]
                          : [Colors.red.shade400, Colors.red.shade600],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _toggleMemberStatusDirect(context, member);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: member.isActive ? Colors.green.shade50 : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: member.isActive ? Colors.green.shade200 : Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  member.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: member.isActive ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.touch_app,
                                  size: 12,
                                  color: member.isActive ? Colors.green.shade700 : Colors.red.shade700,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow(Icons.email, 'Email', member.user?.email ?? 'Not provided'),
              _buildDetailRow(Icons.phone, 'Phone', member.phone),
              _buildDetailRow(Icons.card_membership, 'Membership Type', member.membershipType.toUpperCase()),
              _buildDetailRow(Icons.calendar_today, 'Join Date', member.joinDate?.toString().split(' ')[0] ?? 'Unknown'),
              _buildDetailRow(Icons.schedule, 'Membership Expiry', member.membershipExpiry.toString().split(' ')[0]),
              _buildDetailRow(Icons.contact_emergency, 'Emergency Contact', member.emergencyContactName ?? 'Not provided'),
              _buildDetailRow(Icons.phone_callback, 'Emergency Phone', member.emergencyContactPhone ?? 'Not provided'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  List<Member> _getFilteredMembers(List<Member> members, bool? activeFilter) {
    List<Member> filtered = members;
    
    if (activeFilter != null) {
      filtered = members.where((m) => m.isActive == activeFilter).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((member) => _matchesSearchQuery(member)).toList();
    }
    
    return filtered;
  }

  bool _matchesSearchQuery(Member member) {
    final query = _searchQuery.toLowerCase();
    return member.fullName.toLowerCase().contains(query) ||
           member.phone.toLowerCase().contains(query) ||
           (member.user?.email ?? '').toLowerCase().contains(query) ||
           member.membershipType.toLowerCase().contains(query);
  }

  String _getEmptyTitle(bool? activeFilter) {
    if (activeFilter == null) return 'No members found';
    return activeFilter ? 'No active members' : 'No inactive members';
  }

  String _getEmptySubtitle(bool? activeFilter) {
    if (activeFilter == null) {
      return _searchQuery.isNotEmpty 
          ? 'Try adjusting your search criteria'
          : 'Start by adding your first gym member';
    }
    return activeFilter 
        ? 'All members are currently inactive'
        : 'All members are currently active';
  }

  void _navigateToAddMember(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddMemberScreen(),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}