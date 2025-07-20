import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../providers/member_provider.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart' as common_widgets;

class MemberDetailScreen extends StatefulWidget {
  final Member member;

  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late Member _currentMember;
  MemberProvider? _memberProvider;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
    _currentMember = widget.member;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _memberProvider = Provider.of<MemberProvider>(context, listen: false);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    _memberProvider = null;
    _scaffoldMessenger = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_currentMember.fullName),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _toggleMemberStatus(),
            icon: Icon(
              _currentMember.isActive ? Icons.pause : Icons.play_arrow,
              size: 20,
            ),
            tooltip: _currentMember.isActive ? 'Deactivate Member' : 'Activate Member',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: context.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Member Header Card
            _buildMemberHeaderCard(context),
            SizedBox(height: AppSpacing.lg),
            
            // Personal Information Card
            _buildPersonalInfoCard(context),
            SizedBox(height: AppSpacing.lg),
            
            // Contact Information Card
            _buildContactInfoCard(context),
            SizedBox(height: AppSpacing.lg),
            
            // Emergency Contact Card
            _buildEmergencyContactCard(context),
            SizedBox(height: AppSpacing.lg),
            
            // Physical Attributes Card (if available)
            if (_currentMember.hasPhysicalData) ...[
              _buildPhysicalAttributesCard(context),
              SizedBox(height: AppSpacing.lg),
            ],
            
            // Membership Details Card
            _buildMembershipDetailsCard(context),
            SizedBox(height: AppSpacing.lg),
            
            // Action Buttons
            _buildActionButtons(context),
            SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberHeaderCard(BuildContext context) {
    return common_widgets.ResponsiveCard(
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentMember.isActive ? AppTheme.successGradient : 
                    LinearGradient(
                      colors: [AppTheme.errorRed.withValues(alpha: 0.8), AppTheme.errorRed],
                    ),
                ),
                child: Center(
                  child: Text(
                    _currentMember.fullName.isNotEmpty ? _currentMember.fullName[0].toUpperCase() : 'M',
                    style: AppTextStyles.heading2(context).copyWith(
                      color: Colors.white,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentMember.fullName,
                      style: AppTextStyles.heading2(context),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Member ID: ${_currentMember.memberId ?? 'N/A'}',
                      style: AppTextStyles.body1(context).copyWith(
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    common_widgets.StatusBadge(
                      status: _currentMember.isActive ? 'active' : 'inactive',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context) {
    return common_widgets.ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Personal Information',
                style: AppTextStyles.heading3(context),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            context,
            Icons.email,
            'Email',
            _currentMember.user?.email ?? 'Not provided',
          ),
          
          _buildDetailRow(
            context,
            Icons.phone,
            'Phone',
            _currentMember.phone,
          ),
          
          if (_currentMember.dateOfBirth != null)
            _buildDetailRow(
              context,
              Icons.cake,
              'Date of Birth',
              _formatDate(_currentMember.dateOfBirth!),
            ),
          
          if (_currentMember.age != null)
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Age',
              _currentMember.ageDisplay,
            ),
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(BuildContext context) {
    return common_widgets.ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Contact Information',
                style: AppTextStyles.heading3(context),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            context,
            Icons.home,
            'Address',
            'Address information not available', // TODO: Add address field to member model
            isMultiline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context) {
    return common_widgets.ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Emergency Contact',
                style: AppTextStyles.heading3(context),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            context,
            Icons.contact_emergency,
            'Contact Name',
            _currentMember.emergencyContactName ?? 'Not provided',
          ),
          
          _buildDetailRow(
            context,
            Icons.phone_callback,
            'Contact Phone',
            _currentMember.emergencyContactPhone ?? 'Not provided',
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalAttributesCard(BuildContext context) {
    return common_widgets.ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Physical Attributes',
                style: AppTextStyles.heading3(context),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailRow(
                  context,
                  Icons.height,
                  'Height',
                  _currentMember.heightDisplay,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildDetailRow(
                  context,
                  Icons.monitor_weight,
                  'Weight',
                  _currentMember.weightDisplay,
                ),
              ),
            ],
          ),
          
          if (_currentMember.hasBmi) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBMIColor(_currentMember.bmiCategory).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getBMIColor(_currentMember.bmiCategory).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calculate,
                    color: _getBMIColor(_currentMember.bmiCategory),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI: ${_currentMember.bmiDisplay}',
                        style: AppTextStyles.subtitle1(context).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _currentMember.bmiCategory ?? 'Unknown',
                        style: AppTextStyles.body2(context).copyWith(
                          color: _getBMIColor(_currentMember.bmiCategory),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMembershipDetailsCard(BuildContext context) {
    return common_widgets.ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.card_membership, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Membership Details',
                style: AppTextStyles.heading3(context),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          _buildDetailRow(
            context,
            Icons.stars,
            'Membership Type',
            _currentMember.membershipType.toUpperCase(),
          ),
          
          if (_currentMember.joinDate != null)
            _buildDetailRow(
              context,
              Icons.login,
              'Join Date',
              _formatDate(_currentMember.joinDate!),
            ),
          
          _buildDetailRow(
            context,
            Icons.schedule,
            'Membership Expiry',
            _formatDate(_currentMember.membershipExpiry),
          ),
          
          if (_currentMember.daysUntilExpiry != null)
            _buildDetailRow(
              context,
              Icons.timer,
              'Days Until Expiry',
              '${_currentMember.daysUntilExpiry} days',
              textColor: _currentMember.daysUntilExpiry! <= 7 ? Colors.red : null,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: common_widgets.ResponsiveButton(
                text: _currentMember.isActive ? 'Deactivate Member' : 'Activate Member',
                icon: _currentMember.isActive ? Icons.pause : Icons.play_arrow,
                type: common_widgets.ButtonType.outlined,
                color: _currentMember.isActive ? AppTheme.warningOrange : AppTheme.successGreen,
                onPressed: _toggleMemberStatus,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: common_widgets.ResponsiveButton(
                text: 'Edit Member',
                icon: Icons.edit,
                type: common_widgets.ButtonType.outlined,
                onPressed: () {
                  // TODO: Navigate to edit member screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Edit member functionality coming soon'),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: common_widgets.ResponsiveButton(
                text: 'View Payments',
                icon: Icons.payment,
                type: common_widgets.ButtonType.primary,
                onPressed: () {
                  // TODO: Navigate to member payments screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Member payments view coming soon'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isMultiline = false,
    Color? textColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: AppTheme.textSecondary(context)),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyles.body1(context).copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: AppTextStyles.body1(context).copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: isMultiline ? null : 1,
              overflow: isMultiline ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBMIColor(String? category) {
    if (category == null) return Colors.grey;
    switch (category) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal weight':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _toggleMemberStatus() async {
    if (!mounted || _memberProvider == null || _scaffoldMessenger == null) {
      return;
    }
    
    if (_currentMember.id == null) {
      _scaffoldMessenger!.showSnackBar(
        const SnackBar(
          content: Text('Invalid member ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    try {
      final success = await _memberProvider!.updateMemberStatus(
        _currentMember.id!, 
        !_currentMember.isActive
      );
      
      if (mounted && _scaffoldMessenger != null) {
        if (success) {
          // Update the current member state
          setState(() {
            _currentMember = Member(
              id: _currentMember.id,
              user: _currentMember.user,
              phone: _currentMember.phone,
              dateOfBirth: _currentMember.dateOfBirth,
              membershipType: _currentMember.membershipType,
              joinDate: _currentMember.joinDate,
              membershipExpiry: _currentMember.membershipExpiry,
              isActive: !_currentMember.isActive, // Toggle the status
              emergencyContactName: _currentMember.emergencyContactName,
              emergencyContactPhone: _currentMember.emergencyContactPhone,
              memberId: _currentMember.memberId,
              daysUntilExpiry: _currentMember.daysUntilExpiry,
              heightCm: _currentMember.heightCm,
              weightKg: _currentMember.weightKg,
              bmi: _currentMember.bmi,
              bmiCategory: _currentMember.bmiCategory,
              profilePictureUrl: _currentMember.profilePictureUrl,
              age: _currentMember.age,
            );
          });
          
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(
                'Member ${_currentMember.isActive ? 'activated' : 'deactivated'} successfully'
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          _scaffoldMessenger!.showSnackBar(
            const SnackBar(
              content: Text('Failed to update member status'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          const SnackBar(
            content: Text('Error updating member status'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}