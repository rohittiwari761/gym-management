import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/equipment_provider.dart';
import '../models/equipment.dart';
import '../widgets/network_error_widget.dart';
import '../utils/app_theme.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  EquipmentProvider? _equipmentProvider;
  ScaffoldMessengerState? _scaffoldMessenger;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _equipmentProvider = Provider.of<EquipmentProvider>(context, listen: false);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _equipmentProvider != null) {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _equipmentProvider = null;
    _scaffoldMessenger = null;
    super.dispose();
  }

  Future<void> _loadData() async {
    // Always load all equipment to ensure we show complete list
    await _equipmentProvider!.fetchEquipment(loadAll: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipment Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: 'More actions',
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _clearFilters();
                  break;
                case 'add':
                  _showAddEquipmentDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text('Add Equipment'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, size: 20),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEquipmentListTab(),
                _buildMaintenanceTab(),
                _buildStatisticsTab(),
                _buildWarrantyTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      child: Consumer<EquipmentProvider>(
        builder: (context, provider, child) {
          return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Equipment',
                '${provider.totalEquipment}',
                Icons.fitness_center,
                Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Working',
                '${provider.workingEquipmentCount}',
                Icons.check_circle,
                AppTheme.successGreen,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                'Maintenance',
                '${provider.maintenanceEquipmentCount}',
                Icons.build,
                AppTheme.warningOrange,
              ),
            ),
          ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Equipment'),
          Tab(text: 'Maintenance'),
          Tab(text: 'Stats'),
          Tab(text: 'Warranty'),
        ],
      ),
    );
  }

  Widget _buildEquipmentListTab() {
    return Column(
      children: [
        // Search and Filters
        _buildSearchAndFilters(),
        
        // Add Equipment Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showAddEquipmentDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add New Equipment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Equipment List
        Expanded(
          child: Consumer<EquipmentProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage.isNotEmpty) {
                return NetworkErrorWidget(
                  errorMessage: provider.errorMessage,
                  onRetry: () => provider.fetchEquipment(),
                  retryButtonText: 'Retry Loading Equipment',
                );
              }

              if (provider.equipment.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.fitness_center, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      const Text('No equipment found'),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => provider.fetchEquipment(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.equipment.length,
                  itemBuilder: (context, index) {
                    final equipment = provider.equipment[index];
                    return _buildEquipmentCard(equipment);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Search equipment...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _equipmentProvider?.setSearchQuery(value);
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter Row
          Row(
            children: [
              Expanded(
                child: Consumer<EquipmentProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: provider.selectedCategory,
                      items: provider.equipmentTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          provider.setSelectedCategory(value);
                        }
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              Expanded(
                child: Consumer<EquipmentProvider>(
                  builder: (context, provider, child) {
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      value: provider.selectedStatus,
                      items: ['All', 'Working', 'Maintenance'].map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          provider.setSelectedStatus(value);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEquipmentCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: equipment.isWorking ? AppTheme.successGreen : AppTheme.errorRed,
                  child: Icon(
                    _getEquipmentIcon(equipment.equipmentType),
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Type: ${equipment.equipmentType}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        'Purchase: ${DateFormat('MMM dd, yyyy').format(equipment.purchaseDate)}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      if (equipment.maintenanceNotes.isNotEmpty)
                        Text(
                          'Notes: ${equipment.maintenanceNotes}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: equipment.isWorking 
                            ? AppTheme.successGreen.withValues(alpha: 0.1)
                            : AppTheme.errorRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: equipment.isWorking 
                              ? AppTheme.successGreen.withValues(alpha: 0.3)
                              : AppTheme.errorRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        equipment.statusText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: equipment.isWorking ? AppTheme.successGreen : AppTheme.errorRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleEquipmentAction(value, equipment),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 16),
                              SizedBox(width: 8),
                              Text('View Details'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 16),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'maintenance',
                          child: Row(
                            children: [
                              Icon(Icons.build, size: 16),
                              SizedBox(width: 8),
                              Text('Maintenance'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16, color: AppTheme.errorRed),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, child) {
        final maintenanceEquipment = provider.allEquipment.where((e) => !e.isWorking).toList();
        
        if (maintenanceEquipment.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: AppTheme.successGreen),
                SizedBox(height: 16),
                Text(
                  'All equipment is working!',
                  style: TextStyle(fontSize: 18, color: AppTheme.successGreen),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: maintenanceEquipment.length,
          itemBuilder: (context, index) {
            final equipment = maintenanceEquipment[index];
            return _buildMaintenanceCard(equipment);
          },
        );
      },
    );
  }

  Widget _buildMaintenanceCard(Equipment equipment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: AppTheme.errorRed, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.displayName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Type: ${equipment.equipmentType}',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (equipment.maintenanceNotes.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Maintenance Notes:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(equipment.maintenanceNotes),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsWorking(equipment),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Working'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _updateMaintenanceNotes(equipment),
                  child: const Text('Update Notes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Consumer<EquipmentProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Equipment Statistics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Overview Cards
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.2,
                children: [
                  _buildStatCard(
                    'Total Equipment',
                    '${provider.totalEquipment}',
                    Icons.fitness_center,
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildStatCard(
                    'Working',
                    '${provider.workingEquipmentCount}',
                    Icons.check_circle,
                    AppTheme.successGreen,
                  ),
                  _buildStatCard(
                    'Under Maintenance',
                    '${provider.maintenanceEquipmentCount}',
                    Icons.build,
                    AppTheme.errorRed,
                  ),
                  _buildStatCard(
                    'Equipment Types',
                    '${provider.equipmentTypes.length - 1}', // -1 to exclude 'All'
                    Icons.category,
                    AppTheme.infoBlue,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Equipment by Type
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Equipment by Type',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...provider.equipmentByType.entries.map((entry) => 
                        _buildStatRow(entry.key, '${entry.value}', _getEquipmentIcon(entry.key))
                      ).toList(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Equipment by Brand
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Equipment Brands',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ...provider.equipmentBrands.map((brand) => 
                        _buildStatRow(
                          brand, 
                          '${provider.allEquipment.where((e) => e.brand == brand).length}',
                          Icons.business
                        )
                      ).toList(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWarrantyTab() {
    return Consumer<EquipmentProvider>(
      builder: (context, provider, child) {
        final expiringSoon = provider.expiringSoonWarranty;
        final expired = provider.expiredWarranty;
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Warranty Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              // Expiring Soon
              if (expiringSoon.isNotEmpty) ...[
                Card(
                  color: AppTheme.warningOrange.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: AppTheme.warningOrange),
                            const SizedBox(width: 8),
                            Text(
                              'Warranty Expiring Soon (${expiringSoon.length})',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...expiringSoon.map((equipment) => 
                          _buildWarrantyItem(equipment, Colors.orange)
                        ).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Expired
              if (expired.isNotEmpty) ...[
                Card(
                  color: AppTheme.errorRed.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error, color: AppTheme.errorRed),
                            const SizedBox(width: 8),
                            Text(
                              'Expired Warranty (${expired.length})',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...expired.map((equipment) => 
                          _buildWarrantyItem(equipment, Colors.red)
                        ).toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // All Equipment Warranties
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'All Equipment Warranties',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...provider.allEquipment.map((equipment) => 
                        _buildWarrantyItem(
                          equipment, 
                          equipment.warrantyExpiry.isBefore(DateTime.now()) 
                            ? AppTheme.errorRed
                            : equipment.warrantyExpiry.isBefore(DateTime.now().add(const Duration(days: 30)))
                              ? AppTheme.warningOrange
                              : AppTheme.successGreen
                        )
                      ).toList(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWarrantyItem(Equipment equipment, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getLightColor(color),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getMediumColor(color)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  equipment.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Warranty expires: ${DateFormat('MMM dd, yyyy').format(equipment.warrantyExpiry)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(
            equipment.warrantyExpiry.isBefore(DateTime.now()) 
              ? Icons.error 
              : Icons.warning,
            color: color,
          ),
        ],
      ),
    );
  }

  // Helper function to get a light version of a color
  Color _getLightColor(Color color) {
    if (color == AppTheme.errorRed) return AppTheme.errorRed.withValues(alpha: 0.1);
    if (color == AppTheme.warningOrange) return AppTheme.warningOrange.withValues(alpha: 0.1);
    if (color == AppTheme.successGreen) return AppTheme.successGreen.withValues(alpha: 0.1);
    // Fallback for any other color
    return color.withValues(alpha: 0.1);
  }

  // Helper function to get a medium version of a color
  Color _getMediumColor(Color color) {
    if (color == AppTheme.errorRed) return AppTheme.errorRed.withValues(alpha: 0.3);
    if (color == AppTheme.warningOrange) return AppTheme.warningOrange.withValues(alpha: 0.3);
    if (color == AppTheme.successGreen) return AppTheme.successGreen.withValues(alpha: 0.3);
    // Fallback for any other color
    return color.withValues(alpha: 0.3);
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  IconData _getEquipmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'strength':
        return Icons.fitness_center;
      case 'free weights':
        return Icons.sports_gymnastics;
      case 'functional':
        return Icons.sports_handball;
      case 'recovery':
        return Icons.spa;
      default:
        return Icons.sports_gymnastics;
    }
  }

  void _handleEquipmentAction(String action, Equipment equipment) {
    switch (action) {
      case 'view':
        _showEquipmentDetails(equipment);
        break;
      case 'edit':
        _showEditEquipmentDialog(equipment);
        break;
      case 'maintenance':
        _showMaintenanceDialog(equipment);
        break;
      case 'delete':
        _confirmDelete(equipment);
        break;
    }
  }

  void _showEquipmentDetails(Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(equipment.displayName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Type', equipment.equipmentType),
              _buildDetailRow('Brand', equipment.brand),
              _buildDetailRow('Purchase Date', DateFormat('MMM dd, yyyy').format(equipment.purchaseDate)),
              _buildDetailRow('Warranty Expiry', DateFormat('MMM dd, yyyy').format(equipment.warrantyExpiry)),
              _buildDetailRow('Status', equipment.statusText),
              if (equipment.maintenanceNotes.isNotEmpty)
                _buildDetailRow('Maintenance Notes', equipment.maintenanceNotes),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showAddEquipmentDialog() {
    _showEquipmentDialog();
  }

  void _showEditEquipmentDialog(Equipment equipment) {
    _showEquipmentDialog(equipment: equipment);
  }

  void _showEquipmentDialog({Equipment? equipment}) {
    final isEditing = equipment != null;
    final nameController = TextEditingController(text: equipment?.name ?? '');
    final brandController = TextEditingController(text: equipment?.brand ?? '');
    final notesController = TextEditingController(text: equipment?.maintenanceNotes ?? '');
    
    // Map display names to Django model values
    final typeMapping = {
      'Cardio': 'cardio',
      'Strength': 'strength',
      'Free Weights': 'free_weights',
      'Functional': 'functional',
      'Recovery': 'recovery',
      'Flexibility': 'flexibility',
      'Accessories': 'accessories',
    };
    
    // Reverse mapping for display
    final reverseTypeMapping = {
      'cardio': 'Cardio',
      'strength': 'Strength',
      'free_weights': 'Free Weights',
      'functional': 'Functional',
      'recovery': 'Recovery',
      'flexibility': 'Flexibility',
      'accessories': 'Accessories',
    };
    
    final availableTypes = typeMapping.keys.toList();
    String selectedType = equipment?.equipmentType != null 
        ? reverseTypeMapping[equipment!.equipmentType] ?? 'Cardio'
        : 'Cardio';
    
    DateTime purchaseDate = equipment?.purchaseDate ?? DateTime.now();
    DateTime warrantyDate = equipment?.warrantyExpiry ?? DateTime.now().add(const Duration(days: 365));
    bool isWorking = equipment?.isWorking ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Equipment' : 'Add Equipment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Equipment Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  value: availableTypes.contains(selectedType) ? selectedType : availableTypes.first,
                  items: availableTypes
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: purchaseDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              purchaseDate = date;
                            });
                          }
                        },
                        child: Text('Purchase: ${DateFormat('MMM dd, yyyy').format(purchaseDate)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: warrantyDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                          );
                          if (date != null) {
                            setState(() {
                              warrantyDate = date;
                            });
                          }
                        },
                        child: Text('Warranty: ${DateFormat('MMM dd, yyyy').format(warrantyDate)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Working Status'),
                  subtitle: Text(isWorking ? 'Working' : 'Under Maintenance'),
                  value: isWorking,
                  onChanged: (value) {
                    setState(() {
                      isWorking = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Maintenance Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validate input
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Equipment name is required'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                  return;
                }
                
                if (brandController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Brand is required'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                  return;
                }

                final newEquipment = Equipment(
                  id: equipment?.id,
                  name: nameController.text.trim(),
                  brand: brandController.text.trim(),
                  equipmentType: typeMapping[selectedType] ?? 'cardio', // Convert display name to Django value
                  purchaseDate: purchaseDate,
                  warrantyExpiry: warrantyDate,
                  isWorking: isWorking,
                  condition: isWorking ? 'excellent' : 'maintenance',
                  maintenanceNotes: notesController.text.trim(),
                  quantity: 1, // Default quantity
                );

                bool success;
                if (isEditing) {
                  success = await _equipmentProvider!.updateEquipment(newEquipment);
                } else {
                  success = await _equipmentProvider!.addEquipment(newEquipment);
                }

                if (mounted) {
                  Navigator.of(context).pop();
                  if (_scaffoldMessenger != null) {
                    _scaffoldMessenger!.showSnackBar(
                      SnackBar(
                        content: Text(
                          success 
                            ? '${isEditing ? 'Updated' : 'Added'} equipment successfully'
                            : _equipmentProvider!.errorMessage.isNotEmpty
                                ? _equipmentProvider!.errorMessage
                                : 'Failed to ${isEditing ? 'update' : 'add'} equipment',
                        ),
                        backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                    );
                  }
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMaintenanceDialog(Equipment equipment) {
    final notesController = TextEditingController(text: equipment.maintenanceNotes);
    bool isWorking = equipment.isWorking;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Maintenance - ${equipment.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Working Status'),
                subtitle: Text(isWorking ? 'Working' : 'Under Maintenance'),
                value: isWorking,
                onChanged: (value) {
                  setState(() {
                    isWorking = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Maintenance Notes',
                  border: OutlineInputBorder(),
                  hintText: 'Enter maintenance details...',
                ),
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (equipment.id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Equipment ID is missing'),
                      backgroundColor: AppTheme.errorRed,
                    ),
                  );
                  return;
                }
                
                final success = await _equipmentProvider!.updateMaintenanceStatus(
                  equipment.id!,
                  isWorking,
                  notesController.text.trim(),
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  if (_scaffoldMessenger != null) {
                    _scaffoldMessenger!.showSnackBar(
                      SnackBar(
                        content: Text(
                          success 
                            ? 'Maintenance status updated successfully'
                            : _equipmentProvider!.errorMessage.isNotEmpty
                                ? _equipmentProvider!.errorMessage
                                : 'Failed to update maintenance status',
                        ),
                        backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
                      ),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Equipment equipment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Equipment'),
        content: Text('Are you sure you want to delete "${equipment.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (equipment.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Equipment ID is missing'),
                    backgroundColor: AppTheme.errorRed,
                  ),
                );
                return;
              }
              
              final success = await _equipmentProvider!.deleteEquipment(equipment.id!);

              if (mounted) {
                Navigator.of(context).pop();
                if (_scaffoldMessenger != null) {
                  _scaffoldMessenger!.showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                          ? 'Equipment deleted successfully'
                          : _equipmentProvider!.errorMessage.isNotEmpty
                              ? _equipmentProvider!.errorMessage
                              : 'Failed to delete equipment',
                      ),
                      backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _markAsWorking(Equipment equipment) async {
    if (equipment.id == null) {
      if (_scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          const SnackBar(
            content: Text('Equipment ID is missing'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
      return;
    }
    
    final success = await _equipmentProvider!.updateMaintenanceStatus(
      equipment.id!,
      true,
      'Maintenance completed',
    );

    if (mounted && _scaffoldMessenger != null) {
      _scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? 'Equipment marked as working'
              : 'Failed to update status',
          ),
          backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
        ),
      );
    }
  }

  void _updateMaintenanceNotes(Equipment equipment) {
    final notesController = TextEditingController(text: equipment.maintenanceNotes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Notes - ${equipment.name}'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            labelText: 'Maintenance Notes',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _equipmentProvider!.updateMaintenanceStatus(
                equipment.id!,
                equipment.isWorking,
                notesController.text.trim(),
              );

              if (mounted) {
                Navigator.of(context).pop();
                if (_scaffoldMessenger != null) {
                  _scaffoldMessenger!.showSnackBar(
                    SnackBar(
                      content: Text(
                        success 
                          ? 'Notes updated successfully'
                          : 'Failed to update notes',
                      ),
                      backgroundColor: success ? AppTheme.successGreen : AppTheme.errorRed,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    _searchController.clear();
    _equipmentProvider?.clearFilters();
  }
}