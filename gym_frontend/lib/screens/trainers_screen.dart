import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trainer_provider.dart';
import '../providers/member_provider.dart';
import '../models/trainer.dart';
import '../models/trainer_member_association.dart';
import '../services/trainer_member_association_service.dart';
import '../widgets/network_error_widget.dart';
import '../utils/responsive_utils.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart' as common_widgets;
import 'add_trainer_screen.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key});

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  TrainerProvider? _trainerProvider;
  MemberProvider? _memberProvider;
  ScaffoldMessengerState? _scaffoldMessenger;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely get the provider and scaffold messenger references during dependency changes
    _trainerProvider = Provider.of<TrainerProvider>(context, listen: false);
    _memberProvider = Provider.of<MemberProvider>(context, listen: false);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Load data after getting provider references
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _trainerProvider != null && _memberProvider != null) {
        _trainerProvider!.fetchTrainers();
        _memberProvider!.fetchMembers();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _trainerProvider = null;
    _memberProvider = null;
    _scaffoldMessenger = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Trainers'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _navigateToAddTrainer(context),
            icon: const Icon(Icons.person_add, size: 20),
            tooltip: 'Add Trainer',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTrainerStats(context),
          _buildSearchBar(context),
          _buildTabBar(context),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTrainersList(false), // All trainers
                _buildTrainersList(true),  // Available only
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainerStats(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      child: Consumer<TrainerProvider>(
        builder: (context, provider, child) {
          final availableTrainers = provider.availableTrainers.length;
          final busyTrainers = provider.trainers.length - availableTrainers;
          
          return Row(
            children: [
              Expanded(
                child: _buildEnhancedStatCard(
                  context: context,
                  title: 'Total Trainers',
                  value: '${provider.trainers.length}',
                  icon: Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedStatCard(
                  context: context,
                  title: 'Available',
                  value: '$availableTrainers',
                  icon: Icons.check_circle,
                  color: Colors.green,
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.1),
                      Colors.green.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedStatCard(
                  context: context,
                  title: 'Busy',
                  value: '$busyTrainers',
                  icon: Icons.schedule,
                  color: Colors.orange,
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.1),
                      Colors.orange.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEnhancedStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search trainers by name, specialization, or certification...',
          hintStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, size: 18),
                const SizedBox(width: 8),
                Text('All Trainers'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 18),
                const SizedBox(width: 8),
                Text('Available'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainersList(bool availableOnly) {
    return Consumer<TrainerProvider>(
      builder: (context, trainerProvider, child) {
        if (trainerProvider.isLoading) {
          return const common_widgets.LoadingWidget(message: 'Loading trainers...');
        }

        if (trainerProvider.errorMessage.isNotEmpty) {
          return NetworkErrorWidget(
            errorMessage: trainerProvider.errorMessage,
            onRetry: () => trainerProvider.fetchTrainers(),
            retryButtonText: 'Retry Loading Trainers',
          );
        }

        List<Trainer> filteredTrainers = availableOnly 
            ? _getFilteredTrainers(trainerProvider.availableTrainers, null)
            : _getFilteredTrainers(trainerProvider.trainers, null);

        if (filteredTrainers.isEmpty) {
          return common_widgets.EmptyStateWidget(
            icon: Icons.fitness_center,
            title: _getEmptyTitle(availableOnly),
            subtitle: _getEmptySubtitle(availableOnly),
            actionText: 'Add Trainer',
            onAction: () => _navigateToAddTrainer(context),
          );
        }

        return RefreshIndicator(
          onRefresh: () => trainerProvider.fetchTrainers(),
          child: context.isDesktop
              ? _buildGridView(context, filteredTrainers)
              : _buildListView(context, filteredTrainers),
        );
      },
    );
  }

  Widget _buildListView(BuildContext context, List<Trainer> trainers) {
    return ListView.builder(
      padding: context.screenPadding,
      itemCount: trainers.length,
      itemBuilder: (context, index) {
        final trainer = trainers[index];
        return _buildTrainerCard(context, trainer);
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<Trainer> trainers) {
    return GridView.builder(
      padding: context.screenPadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        childAspectRatio: 1.1,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemCount: trainers.length,
      itemBuilder: (context, index) {
        final trainer = trainers[index];
        return _buildTrainerCard(context, trainer);
      },
    );
  }

  Widget _buildTrainerCard(BuildContext context, Trainer trainer) {
    // Check if trainer matches search query
    if (_searchQuery.isNotEmpty && !_matchesSearchQuery(trainer)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTrainerDetails(context, trainer),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Avatar and Status
                Row(
                  children: [
                    // Enhanced Avatar
                    Stack(
                      children: [
                        Container(
                          width: 65,
                          height: 65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: trainer.isAvailable 
                              ? LinearGradient(
                                  colors: [Colors.green.shade400, Colors.green.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : LinearGradient(
                                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                            boxShadow: [
                              BoxShadow(
                                color: (trainer.isAvailable ? Colors.green : Colors.orange).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              trainer.fullName.isNotEmpty ? trainer.fullName[0].toUpperCase() : 'T',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        // Status indicator
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: trainer.isAvailable ? Colors.green : Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 3,
                              ),
                            ),
                            child: Icon(
                              trainer.isAvailable ? Icons.check : Icons.schedule,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    
                    // Trainer Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trainer.fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              trainer.specialization.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: trainer.isAvailable 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: trainer.isAvailable ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trainer.isAvailable ? Icons.check_circle : Icons.schedule,
                            size: 16,
                            color: trainer.isAvailable ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trainer.isAvailable ? 'Available' : 'Busy',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: trainer.isAvailable ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Details Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildEnhancedInfoRow(
                        context: context,
                        icon: Icons.work_outline,
                        label: 'Experience',
                        value: '${trainer.experienceYears} years',
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      _buildEnhancedInfoRow(
                        context: context,
                        icon: Icons.currency_rupee,
                        label: 'Hourly Rate',
                        value: '₹${trainer.hourlyRate.toStringAsFixed(0)}/hr',
                        color: Colors.green,
                      ),
                      const SizedBox(height: 12),
                      _buildEnhancedInfoRow(
                        context: context,
                        icon: Icons.verified,
                        label: 'Certification',
                        value: trainer.certification,
                        color: Colors.purple,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'View Details',
                        icon: Icons.visibility_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () => _showTrainerDetails(context, trainer),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: trainer.isAvailable ? 'Set Busy' : 'Set Available',
                        icon: trainer.isAvailable ? Icons.pause_circle_outline : Icons.play_circle_outline,
                        color: trainer.isAvailable ? Colors.orange : Colors.green,
                        onPressed: () => _toggleTrainerStatus(context, trainer),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Member Management Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Members',
                        icon: Icons.group_outlined,
                        color: Colors.indigo,
                        onPressed: () => _showAssociatedMembers(context, trainer),
                        isSecondary: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context: context,
                        label: 'Associate',
                        icon: Icons.group_add_outlined,
                        color: Colors.teal,
                        onPressed: () => _showMemberAssociation(context, trainer),
                        isSecondary: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isSecondary = false,
  }) {
    return Material(
      color: isSecondary 
        ? Colors.transparent 
        : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isSecondary 
              ? Border.all(color: color.withOpacity(0.3), width: 1)
              : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: context.smallIconSize,
          color: AppTheme.textSecondary(context),
        ),
        SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body2(context),
          ),
        ),
      ],
    );
  }

  void _showTrainerDetails(BuildContext context, Trainer trainer) {
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
                      gradient: trainer.isAvailable ? AppTheme.successGradient : 
                        LinearGradient(
                          colors: [AppTheme.warningOrange.withValues(alpha: 0.8), AppTheme.warningOrange],
                        ),
                    ),
                    child: Center(
                      child: Text(
                        trainer.fullName.isNotEmpty ? trainer.fullName[0].toUpperCase() : 'T',
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
                          trainer.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            _toggleTrainerStatus(context, trainer);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: trainer.isAvailable ? AppTheme.successGreen.withValues(alpha: 0.1) : AppTheme.warningOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: trainer.isAvailable ? AppTheme.successGreen.withValues(alpha: 0.3) : AppTheme.warningOrange.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  trainer.isAvailable ? 'Available' : 'Busy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: trainer.isAvailable ? AppTheme.successGreen : AppTheme.warningOrange,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.touch_app,
                                  size: 12,
                                  color: trainer.isAvailable ? AppTheme.successGreen : AppTheme.warningOrange,
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
              _buildDetailRow(Icons.phone, 'Phone', trainer.phone),
              _buildDetailRow(Icons.email, 'Email', trainer.user?.email ?? 'Not provided'),
              _buildDetailRow(Icons.fitness_center, 'Specialization', trainer.specialization),
              _buildDetailRow(Icons.work, 'Experience', '${trainer.experienceYears} years'),
              _buildDetailRow(Icons.verified, 'Certification', trainer.certification),
              _buildDetailRow(Icons.currency_rupee, 'Hourly Rate', '₹${trainer.hourlyRate.toStringAsFixed(0)}'),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showMemberAssociation(context, trainer);
                      },
                      child: const Text('Associate Members'),
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

  void _toggleTrainerStatus(BuildContext context, Trainer trainer) async {
    // Check if widget is still mounted and provider is available
    if (!mounted || _trainerProvider == null || _scaffoldMessenger == null) {
      return;
    }
    
    try {
      final success = await _trainerProvider!.updateTrainerAvailability(
        trainer.id!,
        !trainer.isAvailable,
      );

      if (success && mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text(
              'Trainer ${trainer.fullName} is now ${!trainer.isAvailable ? "Available" : "Busy"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text(
              _trainerProvider!.errorMessage.isNotEmpty 
                  ? _trainerProvider!.errorMessage 
                  : 'Failed to update trainer status',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          const SnackBar(
            content: Text('Error updating trainer status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showMemberAssociation(BuildContext context, Trainer trainer) {
    showDialog(
      context: context,
      builder: (context) => _MemberAssociationDialog(trainer: trainer),
    );
  }

  // Helper Methods
  List<Trainer> _getFilteredTrainers(List<Trainer> trainers, bool? availableOnly) {
    List<Trainer> filtered = trainers;
    
    // Only apply availability filter if explicitly requested
    if (availableOnly != null) {
      filtered = trainers.where((t) => t.isAvailable == availableOnly).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((trainer) => _matchesSearchQuery(trainer)).toList();
    }
    
    return filtered;
  }

  bool _matchesSearchQuery(Trainer trainer) {
    final query = _searchQuery.toLowerCase();
    return trainer.fullName.toLowerCase().contains(query) ||
           trainer.specialization.toLowerCase().contains(query) ||
           trainer.certification.toLowerCase().contains(query) ||
           trainer.phone.toLowerCase().contains(query);
  }

  String _getEmptyTitle(bool? availableOnly) {
    if (availableOnly == null) return 'No trainers found';
    return availableOnly ? 'No available trainers' : 'All trainers are available';
  }

  String _getEmptySubtitle(bool? availableOnly) {
    if (availableOnly == null) {
      return _searchQuery.isNotEmpty 
          ? 'Try adjusting your search criteria'
          : 'Start by adding your first trainer';
    }
    return availableOnly 
        ? 'All trainers are currently busy'
        : 'No trainers are currently busy';
  }

  void _navigateToAddTrainer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddTrainerScreen(),
      ),
    );
  }

  void _showAssociatedMembers(BuildContext context, Trainer trainer) {
    showDialog(
      context: context,
      builder: (context) => _AssociatedMembersDialog(trainer: trainer),
    );
  }
}

class _MemberAssociationDialog extends StatefulWidget {
  final Trainer trainer;

  const _MemberAssociationDialog({super.key, required this.trainer});

  @override
  State<_MemberAssociationDialog> createState() => _MemberAssociationDialogState();
}

class _MemberAssociationDialogState extends State<_MemberAssociationDialog> {
  final Set<int> _selectedMemberIds = {};
  final TrainerMemberAssociationService _associationService = TrainerMemberAssociationService();
  Set<int> _alreadyAssociatedMemberIds = {};

  @override
  void initState() {
    super.initState();
    _loadAssociatedMembers();
  }

  Future<void> _loadAssociatedMembers() async {
    try {
      final associations = await _associationService.getTrainerMembers(widget.trainer.id!);
      if (mounted) {
        setState(() {
          _alreadyAssociatedMemberIds = associations.map((a) => a.member.id!).toSet();
        });
      }
    } catch (e) {
      print('Error loading associated members: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Associate Members with ${widget.trainer.fullName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Consumer<MemberProvider>(
          builder: (context, memberProvider, child) {
            if (memberProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Filter out already associated members
            final availableMembers = memberProvider.members
                .where((member) => !_alreadyAssociatedMemberIds.contains(member.id))
                .toList();

            if (availableMembers.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.group_off, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No available members to associate'),
                    SizedBox(height: 8),
                    Text(
                      'All members are already associated with this trainer',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: availableMembers.length,
              itemBuilder: (context, index) {
                final member = availableMembers[index];
                final isSelected = _selectedMemberIds.contains(member.id);

                return CheckboxListTile(
                  title: Text(member.fullName),
                  subtitle: Text(member.phone),
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedMemberIds.add(member.id!);
                      } else {
                        _selectedMemberIds.remove(member.id);
                      }
                    });
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedMemberIds.isEmpty ? null : () async {
            try {
              final associationService = TrainerMemberAssociationService();
              int successCount = 0;
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text('Associating members...'),
                    ],
                  ),
                ),
              );
              
              // Associate each selected member
              for (final memberId in _selectedMemberIds) {
                final success = await associationService.associateMemberWithTrainerViaTrainerEndpoint(
                  widget.trainer.id!,
                  memberId,
                );
                if (success) successCount++;
              }
              
              // Close loading dialog
              if (mounted) Navigator.pop(context);
              
              // Show result
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      successCount == _selectedMemberIds.length
                          ? 'Successfully associated ${successCount} members with ${widget.trainer.fullName}'
                          : 'Associated ${successCount}/${_selectedMemberIds.length} members with ${widget.trainer.fullName}',
                    ),
                    backgroundColor: successCount > 0 ? Colors.green : Colors.red,
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              // Close loading dialog if still open
              if (mounted) Navigator.pop(context);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error associating members: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: const Text('Associate'),
        ),
      ],
    );
  }
}

class _AssociatedMembersDialog extends StatefulWidget {
  final Trainer trainer;

  const _AssociatedMembersDialog({super.key, required this.trainer});

  @override
  State<_AssociatedMembersDialog> createState() => _AssociatedMembersDialogState();
}

class _AssociatedMembersDialogState extends State<_AssociatedMembersDialog> {
  final TrainerMemberAssociationService _associationService = TrainerMemberAssociationService();
  List<TrainerMemberAssociation> _associations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAssociations();
  }

  Future<void> _loadAssociations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final associations = await _associationService.getTrainerMembers(widget.trainer.id!);
      
      if (mounted) {
        setState(() {
          _associations = associations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _removeAssociation(TrainerMemberAssociation association) async {
    try {
      final success = await _associationService.unassociateMemberFromTrainerViaTrainerEndpoint(
        widget.trainer.id!,
        association.member.id!,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${association.member.fullName} removed from ${widget.trainer.fullName}'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the list
        _loadAssociations();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove association'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing association: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Members Trained by ${widget.trainer.fullName}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading associations: $_error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadAssociations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _associations.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No members associated',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Associate members with this trainer to see them here',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _associations.length,
                        itemBuilder: (context, index) {
                          final association = _associations[index];
                          final member = association.member;
                
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: member.isActive ? Colors.blue : Colors.grey,
                                child: Text(
                                  member.fullName.isNotEmpty 
                                      ? member.fullName[0].toUpperCase() 
                                      : 'M',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text(member.fullName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(member.phone),
                                  Text(
                                    'Membership: ${member.membershipType.toUpperCase()}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Associated: ${association.assignedDate.day}/${association.assignedDate.month}/${association.assignedDate.year}',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: member.isActive 
                                          ? Colors.green.shade50 
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: member.isActive 
                                            ? Colors.green.shade200 
                                            : Colors.red.shade200,
                                      ),
                                    ),
                                    child: Text(
                                      member.isActive ? 'Active' : 'Inactive',
                                      style: TextStyle(
                                        color: member.isActive 
                                            ? Colors.green.shade700 
                                            : Colors.red.shade700,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Remove Association'),
                                          content: Text(
                                            'Are you sure you want to remove ${member.fullName} from ${widget.trainer.fullName}?'
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () => Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                              ),
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      );
                                      
                                      if (confirmed == true) {
                                        await _removeAssociation(association);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Open member association dialog
            showDialog(
              context: context,
              builder: (context) => _MemberAssociationDialog(trainer: widget.trainer),
            );
          },
          child: const Text('Add Members'),
        ),
      ],
    );
  }
}

// Legacy code for backward compatibility
class _OldTrainerCard extends StatelessWidget {
  final Trainer trainer;

  const _OldTrainerCard({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: trainer.isAvailable ? Colors.green : Colors.orange,
          child: Text(
            trainer.fullName.isNotEmpty ? trainer.fullName[0].toUpperCase() : 'T',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(trainer.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialization: ${trainer.specialization}'),
            Text('Experience: ${trainer.experienceYears} years'),
            Text('Rate: ₹${trainer.hourlyRate.toStringAsFixed(2)}/hour'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              trainer.isAvailable ? Icons.check_circle : Icons.schedule,
              color: trainer.isAvailable ? Colors.green : Colors.orange,
            ),
            Text(
              trainer.isAvailable ? 'Available' : 'Busy',
              style: TextStyle(
                fontSize: 12,
                color: trainer.isAvailable ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        onTap: () {
          _showTrainerDetails(context, trainer);
        },
      ),
    );
  }

  void _showTrainerDetails(BuildContext context, Trainer trainer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(trainer.fullName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phone: ${trainer.phone}'),
            Text('Email: ${trainer.user?.email ?? 'Not provided'}'),
            Text('Specialization: ${trainer.specialization}'),
            Text('Experience: ${trainer.experienceYears} years'),
            Text('Certification: ${trainer.certification}'),
            Text('Hourly Rate: ₹${trainer.hourlyRate.toStringAsFixed(2)}'),
            Text('Status: ${trainer.isAvailable ? 'Available' : 'Busy'}'),
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