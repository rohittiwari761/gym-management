import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final isExpiringSoon = _currentMember.daysUntilExpiry != null && _currentMember.daysUntilExpiry! <= 7;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _currentMember.isActive 
            ? [Theme.of(context).colorScheme.primaryContainer, Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)]
            : [Colors.grey.shade200, Colors.grey.shade100],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              // Enhanced Avatar with Border
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _currentMember.isActive 
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade600],
                      ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: _currentMember.profilePictureUrl != null
                    ? ClipOval(
                        child: Image.network(
                          _currentMember.profilePictureUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              _currentMember.fullName.isNotEmpty ? _currentMember.fullName[0].toUpperCase() : 'M',
                              style: AppTextStyles.heading2(context).copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          _currentMember.fullName.isNotEmpty ? _currentMember.fullName[0].toUpperCase() : 'M',
                          style: AppTextStyles.heading2(context).copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                ),
              ),
              SizedBox(width: AppSpacing.lg),
              
              // Enhanced Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentMember.fullName,
                      style: AppTextStyles.heading2(context).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.badge,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          _currentMember.memberId ?? 'N/A',
                          style: AppTextStyles.body1(context).copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        common_widgets.StatusBadge(
                          status: _currentMember.isActive ? 'active' : 'inactive',
                        ),
                        if (isExpiringSoon) ...[
                          SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning, size: 12, color: Colors.orange.shade700),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  '${_currentMember.daysUntilExpiry} days left',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Quick Action Buttons Row
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.phone,
                  label: 'Call',
                  color: Colors.green,
                  onTap: () => _makePhoneCall(_currentMember.phone),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.message,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _openWhatsApp(_currentMember.phone),
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  icon: Icons.email,
                  label: 'Email',
                  color: Colors.blue,
                  onTap: () => _sendEmail(_currentMember.user?.email),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.caption(context).copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
            'Not provided', // TODO: Add address field to member model when available
            isMultiline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context) {
    final hasEmergencyContact = _currentMember.emergencyContactName != null && 
                               _currentMember.emergencyContactName!.isNotEmpty;
    
    return common_widgets.ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emergency, color: Colors.red.shade600),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Emergency Contact',
                style: AppTextStyles.heading3(context),
              ),
              const Spacer(),
              if (hasEmergencyContact && _currentMember.emergencyContactPhone != null)
                InkWell(
                  onTap: () => _openWhatsApp(_currentMember.emergencyContactPhone!),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.message, size: 14, color: const Color(0xFF25D366)),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF25D366),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          
          if (hasEmergencyContact) ...[
            _buildDetailRow(
              context,
              Icons.person,
              'Contact Name',
              _currentMember.emergencyContactName!,
            ),
            
            if (_currentMember.emergencyContactPhone != null && _currentMember.emergencyContactPhone!.isNotEmpty)
              _buildDetailRow(
                context,
                Icons.phone,
                'Phone Number',
                _currentMember.emergencyContactPhone!,
                actionIcon: Icons.phone,
                onAction: () => _makePhoneCall(_currentMember.emergencyContactPhone!),
              ),
          ] else ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'No emergency contact information provided',
                      style: AppTextStyles.body2(context).copyWith(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
    final isExpiringSoon = _currentMember.daysUntilExpiry != null && _currentMember.daysUntilExpiry! <= 7;
    
    return Column(
      children: [
        // Main Action Buttons
        Row(
          children: [
            Expanded(
              child: common_widgets.ResponsiveButton(
                text: 'Edit Member',
                icon: Icons.edit,
                type: common_widgets.ButtonType.outlined,
                onPressed: () => _editMember(context),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: common_widgets.ResponsiveButton(
                text: 'View Payments',
                icon: Icons.payment,
                type: common_widgets.ButtonType.filled,
                onPressed: () => _viewPayments(context),
              ),
            ),
          ],
        ),
        
        // WhatsApp Reminder Buttons (if expiring soon)
        if (isExpiringSoon) ...[
          SizedBox(height: AppSpacing.md),
          Container(
            padding: EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Membership expires in ${_currentMember.daysUntilExpiry} days',
                        style: AppTextStyles.body2(context).copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: common_widgets.ResponsiveButton(
                        text: 'Send Reminder',
                        icon: Icons.message,
                        type: common_widgets.ButtonType.outlined,
                        color: const Color(0xFF25D366),
                        onPressed: () => _sendReminderWhatsApp('expiry'),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: common_widgets.ResponsiveButton(
                        text: 'Payment Reminder',
                        icon: Icons.payment,
                        type: common_widgets.ButtonType.outlined,
                        color: const Color(0xFF25D366),
                        onPressed: () => _sendReminderWhatsApp('payment'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    IconData? actionIcon,
    VoidCallback? onAction,
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
            child: Row(
              children: [
                Expanded(
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
                if (actionIcon != null && onAction != null) ...[
                  SizedBox(width: AppSpacing.sm),
                  InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        actionIcon,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
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

  // Enhanced functionality methods
  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendEmail(String? email) async {
    if (email == null || email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email address available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Gym Membership - ${_currentMember.fullName}',
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email app'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    // Remove any formatting from phone number
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Add country code if not present
    if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+91$cleanNumber'; // Default to India, adjust as needed
    }

    final uri = Uri.parse('https://wa.me/$cleanNumber');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendReminderWhatsApp(String type) async {
    String message = '';
    final memberName = _currentMember.fullName;
    final daysLeft = _currentMember.daysUntilExpiry ?? 0;
    
    if (type == 'expiry') {
      message = '''
Hello $memberName! 👋

🚨 *Membership Expiry Reminder*

Your gym membership will expire in *$daysLeft days*.

Please renew your membership to continue enjoying our facilities.

For renewal, please contact us or visit the gym.

Thank you! 💪
      ''';
    } else if (type == 'payment') {
      message = '''
Hello $memberName! 👋

💰 *Payment Reminder*

Your gym membership payment is due soon (expires in $daysLeft days).

Please make your payment to avoid any interruption in your membership.

For payment options, please contact us.

Thank you! 💪
      ''';
    }

    String cleanNumber = _currentMember.phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (!cleanNumber.startsWith('+')) {
      cleanNumber = '+91$cleanNumber';
    }

    final encodedMessage = Uri.encodeComponent(message);
    final uri = Uri.parse('https://wa.me/$cleanNumber?text=$encodedMessage');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editMember(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Member'),
        content: const Text('Edit member functionality will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewPayments(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('View Payments'),
        content: const Text('Payment history functionality will be available in the next update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}