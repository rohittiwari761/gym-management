import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../models/member.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_theme.dart';
import 'common_widgets.dart' as common_widgets;

class WebMemberDataTable extends StatefulWidget {
  final List<Member> members;
  final Function(Member) onMemberTap;
  final Function(Member) onMemberEdit;
  final Function(Member) onMemberToggle;
  final Function(String)? onSearch;
  final bool isLoading;

  const WebMemberDataTable({
    super.key,
    required this.members,
    required this.onMemberTap,
    required this.onMemberEdit,
    required this.onMemberToggle,
    this.onSearch,
    this.isLoading = false,
  });

  @override
  State<WebMemberDataTable> createState() => _WebMemberDataTableState();
}

class _WebMemberDataTableState extends State<WebMemberDataTable> {
  int? _sortColumnIndex;
  bool _sortAscending = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedRowCount = 0;
  final Set<String> _selectedMembers = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For non-web platforms, return empty container
    if (!kIsWeb || !context.isWebDesktop) {
      return Container();
    }

    return Card(
      elevation: context.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.webCardBorderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTableHeader(context),
          if (widget.isLoading)
            const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildDataTable(context),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(context.webCardBorderRadius),
          topRight: Radius.circular(context.webCardBorderRadius),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Members Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.members.length} total members',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedRowCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$_selectedRowCount selected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          SizedBox(
            width: 300,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          widget.onSearch?.call('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                widget.onSearch?.call(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context) {
    final filteredMembers = _getFilteredMembers();
    
    if (filteredMembers.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty ? 'No members found' : 'No members available',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty 
                    ? 'Try adjusting your search criteria'
                    : 'Add your first member to get started',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 100,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dataTableTheme: DataTableThemeData(
                headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return AppTheme.primaryBlue.withOpacity(0.05);
                  }
                  return Colors.white;
                }),
                dividerThickness: 1,
                horizontalMargin: 24,
                columnSpacing: 32,
              ),
            ),
            child: DataTable(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              showCheckboxColumn: true,
              headingRowHeight: 56,
              dataRowHeight: 72,
              columns: _buildColumns(context),
              rows: _buildRows(context, filteredMembers),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns(BuildContext context) {
    return [
      DataColumn(
        label: Text(
          'Member',
          style: TextStyle(
            fontSize: context.webTableHeaderFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        onSort: (columnIndex, ascending) => _sort(columnIndex, ascending, (member) => member.fullName),
      ),
      DataColumn(
        label: Text(
          'Contact',
          style: TextStyle(
            fontSize: context.webTableHeaderFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
      DataColumn(
        label: Text(
          'Membership',
          style: TextStyle(
            fontSize: context.webTableHeaderFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        onSort: (columnIndex, ascending) => _sort(columnIndex, ascending, (member) => member.membershipType),
      ),
      DataColumn(
        label: Text(
          'Status',
          style: TextStyle(
            fontSize: context.webTableHeaderFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        onSort: (columnIndex, ascending) => _sort(columnIndex, ascending, (member) => member.isActive ? 'Active' : 'Inactive'),
      ),
      DataColumn(
        label: Text(
          'Actions',
          style: TextStyle(
            fontSize: context.webTableHeaderFontSize,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    ];
  }

  List<DataRow> _buildRows(BuildContext context, List<Member> members) {
    return members.map((member) {
      final isSelected = _selectedMembers.contains(member.id);
      
      return DataRow(
        selected: isSelected,
        onSelectChanged: (selected) {
          setState(() {
            if (selected == true) {
              _selectedMembers.add(member.id?.toString() ?? '');
            } else {
              _selectedMembers.remove(member.id);
            }
            _selectedRowCount = _selectedMembers.length;
          });
        },
        cells: [
          DataCell(_buildMemberCell(context, member)),
          DataCell(_buildContactCell(context, member)),
          DataCell(_buildMembershipCell(context, member)),
          DataCell(_buildStatusCell(context, member)),
          DataCell(_buildActionsCell(context, member)),
        ],
      );
    }).toList();
  }

  Widget _buildMemberCell(BuildContext context, Member member) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: member.isActive ? AppTheme.successGradient : 
              LinearGradient(
                colors: [AppTheme.errorRed.withOpacity(0.8), AppTheme.errorRed],
              ),
          ),
          child: Center(
            child: Text(
              member.fullName.isNotEmpty ? member.fullName[0].toUpperCase() : 'M',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                member.fullName,
                style: TextStyle(
                  fontSize: context.webTableBodyFontSize + 1,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (member.emergencyContactName?.isNotEmpty == true) ...[
                const SizedBox(height: 2),
                Text(
                  'Emergency: ${member.emergencyContactName}',
                  style: TextStyle(
                    fontSize: context.webTableBodyFontSize - 1,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactCell(BuildContext context, Member member) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => _launchPhone(member.phone),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone,
                size: 14,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 4),
              Text(
                member.phone,
                style: TextStyle(
                  fontSize: context.webTableBodyFontSize,
                  color: AppTheme.primaryBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (member.user?.email?.isNotEmpty == true)
          InkWell(
            onTap: () => _launchEmail(member.user!.email!),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email,
                  size: 14,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    member.user!.email!,
                    style: TextStyle(
                      fontSize: context.webTableBodyFontSize,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMembershipCell(BuildContext context, Member member) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        member.membershipType.toUpperCase(),
        style: TextStyle(
          fontSize: context.webTableBodyFontSize,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildStatusCell(BuildContext context, Member member) {
    return common_widgets.StatusBadge(
      status: member.isActive ? 'active' : 'inactive',
    );
  }

  Widget _buildActionsCell(BuildContext context, Member member) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => widget.onMemberTap(member),
          icon: Icon(
            Icons.visibility_outlined,
            size: context.webActionIconSize,
            color: Colors.grey.shade600,
          ),
          tooltip: 'View Details',
        ),
        IconButton(
          onPressed: () => widget.onMemberEdit(member),
          icon: Icon(
            Icons.edit_outlined,
            size: context.webActionIconSize,
            color: AppTheme.primaryBlue,
          ),
          tooltip: 'Edit Member',
        ),
        IconButton(
          onPressed: () => widget.onMemberToggle(member),
          icon: Icon(
            member.isActive ? Icons.pause_outlined : Icons.play_arrow_outlined,
            size: context.webActionIconSize,
            color: member.isActive ? AppTheme.warningOrange : AppTheme.successGreen,
          ),
          tooltip: member.isActive ? 'Deactivate' : 'Activate',
        ),
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: context.webActionIconSize,
            color: Colors.grey.shade600,
          ),
          tooltip: 'More Options',
          onSelected: (value) => _handleMenuAction(value, member),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'whatsapp',
              child: ListTile(
                leading: Icon(Icons.message, size: 18),
                title: Text('Send WhatsApp'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'payments',
              child: ListTile(
                leading: Icon(Icons.payment, size: 18),
                title: Text('View Payments'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, size: 18, color: Colors.red),
                title: Text('Delete Member', style: TextStyle(color: Colors.red)),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Member> _getFilteredMembers() {
    if (_searchQuery.isEmpty) return widget.members;
    
    return widget.members.where((member) {
      final query = _searchQuery.toLowerCase();
      return member.fullName.toLowerCase().contains(query) ||
             member.phone.toLowerCase().contains(query) ||
             (member.user?.email ?? '').toLowerCase().contains(query) ||
             member.membershipType.toLowerCase().contains(query);
    }).toList();
  }

  void _sort<T>(int columnIndex, bool ascending, T Function(Member) getField) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      
      widget.members.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return ascending ? -1 : 1;
        if (bValue == null) return ascending ? 1 : -1;
        
        return ascending 
            ? Comparable.compare(aValue as Comparable, bValue as Comparable)
            : Comparable.compare(bValue as Comparable, aValue as Comparable);
      });
    });
  }

  void _handleMenuAction(String action, Member member) {
    switch (action) {
      case 'whatsapp':
        _launchWhatsApp(member.phone);
        break;
      case 'payments':
        Navigator.pushNamed(context, '/payments', arguments: member.id);
        break;
      case 'delete':
        _showDeleteConfirmation(member);
        break;
    }
  }

  void _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchWhatsApp(String phone) async {
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showDeleteConfirmation(Member member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Are you sure you want to delete ${member.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}