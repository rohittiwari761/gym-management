import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions Row
                  _buildQuickActionsRow(context),
                  const SizedBox(height: 20),
                  
                  // Main Content
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Use single column layout for mobile/narrow screens and web
                      if (kIsWeb || constraints.maxWidth < 800) {
                        return Column(
                          children: [
                            _buildPersonalInfoCard(context),
                            const SizedBox(height: 16),
                            _buildContactInfoCard(context),
                            const SizedBox(height: 16),
                            _buildEmergencyContactCard(context),
                            const SizedBox(height: 16),
                            _buildMembershipCard(context),
                            if (_currentMember.hasPhysicalData) ...[
                              const SizedBox(height: 16),
                              _buildPhysicalAttributesCard(context),
                            ],
                          ],
                        );
                      }
                      
                      // Two column layout for wider screens
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                _buildPersonalInfoCard(context),
                                const SizedBox(height: 16),
                                _buildContactInfoCard(context),
                                const SizedBox(height: 16),
                                _buildEmergencyContactCard(context),
                              ],
                            ),
                          ),
                          
                          const SizedBox(width: 16),
                          
                          // Right Column
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                _buildMembershipCard(context),
                                if (_currentMember.hasPhysicalData) ...[
                                  const SizedBox(height: 16),
                                  _buildPhysicalAttributesCard(context),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    final isExpiringSoon = _currentMember.daysUntilExpiry != null && _currentMember.daysUntilExpiry! <= 7;
    
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _currentMember.isActive 
                ? [Colors.blue.shade50, Colors.blue.shade100]
                : [Colors.grey.shade100, Colors.grey.shade200],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  Hero(
                    tag: 'member-${_currentMember.id}',
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: _currentMember.isActive 
                            ? LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade600],
                              )
                            : LinearGradient(
                                colors: [Colors.grey.shade400, Colors.grey.shade600],
                              ),
                        ),
                        child: Center(
                          child: Text(
                            _currentMember.fullName.isNotEmpty ? _currentMember.fullName[0].toUpperCase() : 'M',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Name and Status
                  Text(
                    _currentMember.fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _currentMember.isActive ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _currentMember.isActive ? 'Active' : 'Inactive',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isExpiringSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, size: 14, color: Colors.red.shade700),
                              const SizedBox(width: 4),
                              Text(
                                '${_currentMember.daysUntilExpiry} days left',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    _currentMember.membershipType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _toggleMemberStatus(),
          icon: Icon(
            _currentMember.isActive ? Icons.pause : Icons.play_arrow,
            color: _currentMember.isActive ? Colors.orange : Colors.green,
          ),
          tooltip: _currentMember.isActive ? 'Deactivate Member' : 'Activate Member',
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.phone,
            label: 'Call',
            color: Colors.green,
            onTap: () => _makePhoneCall(_currentMember.phone),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.message,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            onTap: () => _openWhatsApp(_currentMember.phone),
            isHighlighted: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.email,
            label: 'Email',
            color: Colors.blue,
            onTap: () => _sendEmail(_currentMember.user?.email),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isHighlighted = false,
  }) {
    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlighted ? color : Colors.grey.shade200,
              width: isHighlighted ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon, 
                  color: color, 
                  size: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context) {
    return _buildModernCard(
      title: 'Personal Information',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _buildModernDetailRow(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: _currentMember.user?.email ?? 'Not provided',
            actionIcon: Icons.email,
            onAction: () => _sendEmail(_currentMember.user?.email),
          ),
          const SizedBox(height: 16),
          _buildModernDetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: _currentMember.phone,
            actionIcon: Icons.call,
            onAction: () => _makePhoneCall(_currentMember.phone),
          ),
          if (_currentMember.dateOfBirth != null) ...[
            const SizedBox(height: 16),
            _buildModernDetailRow(
              icon: Icons.cake_outlined,
              label: 'Date of Birth',
              value: _formatDate(_currentMember.dateOfBirth!),
            ),
          ],
          if (_currentMember.age != null) ...[
            const SizedBox(height: 16),
            _buildModernDetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Age',
              value: _currentMember.ageDisplay,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactInfoCard(BuildContext context) {
    return _buildModernCard(
      title: 'Contact Information',
      icon: Icons.location_on_outlined,
      child: Column(
        children: [
          _buildModernDetailRow(
            icon: Icons.home_outlined,
            label: 'Home Address',
            value: _currentMember.address?.isNotEmpty == true 
                ? _currentMember.address! 
                : 'Not provided',
            isMultiline: true,
          ),
          const SizedBox(height: 16),
          _buildModernDetailRow(
            icon: Icons.badge_outlined,
            label: 'Member ID',
            value: _currentMember.memberId ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactCard(BuildContext context) {
    final hasEmergencyContact = _currentMember.emergencyContactName != null && 
                               _currentMember.emergencyContactName!.isNotEmpty;
    
    return _buildModernCard(
      title: 'Emergency Contact',
      icon: Icons.emergency_outlined,
      iconColor: Colors.red.shade600,
      child: hasEmergencyContact
        ? Column(
            children: [
              _buildModernDetailRow(
                icon: Icons.person_outline,
                label: 'Contact Name',
                value: _currentMember.emergencyContactName!,
              ),
              if (_currentMember.emergencyContactRelation != null && _currentMember.emergencyContactRelation!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildModernDetailRow(
                  icon: Icons.family_restroom_outlined,
                  label: 'Relationship',
                  value: _currentMember.emergencyContactRelation!,
                ),
              ],
              if (_currentMember.emergencyContactPhone != null && _currentMember.emergencyContactPhone!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildModernDetailRow(
                  icon: Icons.phone_outlined,
                  label: 'Phone Number',
                  value: _currentMember.emergencyContactPhone!,
                  actionIcon: Icons.call,
                  onAction: () => _makePhoneCall(_currentMember.emergencyContactPhone!),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(_currentMember.emergencyContactPhone!),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('WhatsApp Contact'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          )
        : Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No emergency contact information provided',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildPhysicalAttributesCard(BuildContext context) {
    return _buildModernCard(
      title: 'Physical Attributes',
      icon: Icons.fitness_center_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.height, color: Colors.blue.shade600, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        _currentMember.heightDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Height',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.monitor_weight, color: Colors.green.shade600, size: 20),
                      const SizedBox(height: 6),
                      Text(
                        _currentMember.weightDisplay,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Weight',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          if (_currentMember.hasBmi) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _getBMIColor(_currentMember.bmiCategory).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getBMIColor(_currentMember.bmiCategory).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getBMIColor(_currentMember.bmiCategory).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.calculate,
                      color: _getBMIColor(_currentMember.bmiCategory),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BMI: ${_currentMember.bmiDisplay}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _currentMember.bmiCategory ?? 'Unknown',
                          style: TextStyle(
                            color: _getBMIColor(_currentMember.bmiCategory),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

  Widget _buildMembershipCard(BuildContext context) {
    final isExpiringSoon = _currentMember.daysUntilExpiry != null && _currentMember.daysUntilExpiry! <= 7;
    
    return _buildModernCard(
      title: 'Membership',
      icon: Icons.card_membership_outlined,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.blue.shade100],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _currentMember.membershipType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Membership Plan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_currentMember.joinDate != null)
            _buildModernDetailRow(
              icon: Icons.login_outlined,
              label: 'Join Date',
              value: _formatDate(_currentMember.joinDate!),
            ),
          
          const SizedBox(height: 16),
          
          _buildModernDetailRow(
            icon: Icons.schedule_outlined,
            label: 'Expiry Date',
            value: _formatDate(_currentMember.membershipExpiry),
          ),
          
          if (_currentMember.daysUntilExpiry != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isExpiringSoon ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpiringSoon ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isExpiringSoon ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: isExpiringSoon ? Colors.red.shade700 : Colors.green.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_currentMember.daysUntilExpiry} days until expiry',
                      style: TextStyle(
                        color: isExpiringSoon ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
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

  Widget _buildActionButtons(BuildContext context) {
    final isExpiringSoon = _currentMember.daysUntilExpiry != null && _currentMember.daysUntilExpiry! <= 7;
    
    return Column(
      children: [
        // Main Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _editMember(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _viewPayments(context),
                icon: const Icon(Icons.payment, size: 16),
                label: const Text('Payments'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // WhatsApp Reminder Section (if expiring soon)
        if (isExpiringSoon) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade50, Colors.orange.shade100],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Membership expires in ${_currentMember.daysUntilExpiry} days',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sendReminderWhatsApp('expiry'),
                        icon: const Icon(Icons.message, size: 16),
                        label: const Text('Reminder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _sendReminderWhatsApp('payment'),
                        icon: const Icon(Icons.payment, size: 16),
                        label: const Text('Payment'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (iconColor ?? Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildModernDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
    Color? textColor,
    IconData? actionIcon,
    VoidCallback? onAction,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? Colors.black87,
                  ),
                  maxLines: isMultiline ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (actionIcon != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  actionIcon,
                  size: 16,
                  color: Colors.blue,
                ),
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