import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trainer_provider.dart';
import '../widgets/lazy_loading_list.dart';
import '../widgets/responsive_wrapper.dart';
import '../utils/performance_monitor.dart';
import '../utils/debouncer.dart';

class OptimizedTrainersScreen extends StatefulWidget {
  const OptimizedTrainersScreen({super.key});

  @override
  State<OptimizedTrainersScreen> createState() => _OptimizedTrainersScreenState();
}

class _OptimizedTrainersScreenState extends State<OptimizedTrainersScreen> 
    with PerformanceMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(delay: const Duration(milliseconds: 300));
  bool _isSearching = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    startPerformanceTimer('trainers_screen_init');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      stopPerformanceTimer('trainers_screen_init');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final trainerProvider = context.read<TrainerProvider>();
    await trainerProvider.fetchTrainers();
  }

  void _onSearchChanged(String query) {
    _debouncer.run(() {
      setState(() {
        _isSearching = query.isNotEmpty;
      });
      // Note: This would need to be implemented in trainer provider
      // context.read<TrainerProvider>().searchTrainers(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _isSearching = false;
    });
    // context.read<TrainerProvider>().clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return PerformanceWrapper(
      name: 'trainers_screen',
      child: ResponsiveWrapper(
        child: Scaffold(
          appBar: _buildAppBar(),
          body: _buildBody(),
          floatingActionButton: _buildFab(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Trainers'),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: _buildSearchBar(),
      ),
      actions: [
        IconButton(
          onPressed: () => _loadInitialData(),
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search trainers...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<TrainerProvider>(
      builder: (context, trainerProvider, child) {
        if (trainerProvider.isLoading && trainerProvider.trainers.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading trainers...'),
              ],
            ),
          );
        }

        if (trainerProvider.errorMessage != null && trainerProvider.trainers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  trainerProvider.errorMessage!,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => trainerProvider.fetchTrainers(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => trainerProvider.fetchTrainers(),
          child: trainerProvider.trainers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _isSearching 
                            ? 'No trainers found matching your search'
                            : 'No trainers found. Add your first trainer!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: trainerProvider.trainers.length,
                  itemBuilder: (context, index) {
                    final trainer = trainerProvider.trainers[index];
                    return OptimizedTrainerTile(
                      key: ValueKey(trainer.id),
                      name: trainer.fullName,
                      specialization: trainer.specialization,
                      phone: trainer.phone,
                      isActive: trainer.isAvailable,
                      memberCount: 0,
                      onTap: () => _showTrainerDetails(trainer),
                      // onToggleStatus: () => _toggleTrainerStatus(trainer),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildFab() {
    return FloatingActionButton(
      onPressed: _addTrainer,
      backgroundColor: Theme.of(context).primaryColor,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  void _showTrainerDetails(dynamic trainer) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _TrainerDetailsSheet(trainer: trainer),
    );
  }

  void _addTrainer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Trainer'),
        content: const Text('Add trainer functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _editTrainer(dynamic trainer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Trainer'),
        content: Text('Edit functionality for ${trainer.fullName} will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleTrainerStatus(dynamic trainer) async {
    final trainerProvider = context.read<TrainerProvider>();
    
    final action = trainer.isAvailable ? 'deactivate' : 'activate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.toUpperCase()} Trainer'),
        content: Text('Are you sure you want to $action ${trainer.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: trainer.isAvailable ? Colors.orange : Colors.blue,
            ),
            child: Text(action.toUpperCase()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement toggleTrainerStatus method in TrainerProvider
        final success = false; // await trainerProvider.toggleTrainerStatus(trainer.id);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${trainer.fullName} has been ${action}d successfully'),
              backgroundColor: trainer.isAvailable ? Colors.orange : Colors.blue,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to $action trainer: ${trainerProvider.errorMessage}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to $action trainer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _TrainerDetailsSheet extends StatelessWidget {
  final dynamic trainer;

  const _TrainerDetailsSheet({required this.trainer});

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildDetails(),
            const SizedBox(height: 16),
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: trainer.isAvailable ? Colors.blue : Colors.grey,
          child: Text(
            trainer.fullName.isNotEmpty ? trainer.fullName[0].toUpperCase() : 'T',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
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
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                trainer.specialization,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow('Phone', trainer.phone),
        _buildDetailRow('Status', trainer.isAvailable ? 'Available' : 'Unavailable'),
        _buildDetailRow('Experience', '${trainer.experienceYears} years'),
        _buildDetailRow('Specialization', trainer.specialization),
      ],
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
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.edit),
          label: const Text('Edit'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.assignment),
          label: const Text('Assign Members'),
        ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.schedule),
          label: const Text('Schedule'),
        ),
      ],
    );
  }
}