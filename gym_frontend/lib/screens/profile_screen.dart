import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../providers/user_profile_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/html_decoder.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  UserProfileProvider? _profileProvider;
  ScaffoldMessengerState? _scaffoldMessenger;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely get the provider and scaffold messenger references during dependency changes
    _profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _profileProvider != null) {
        _profileProvider!.fetchCurrentProfile();
      }
    });
  }

  @override
  void dispose() {
    _profileProvider = null;
    _scaffoldMessenger = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<UserProfileProvider>(
        builder: (context, profileProvider, child) {
          if (profileProvider.isLoading && profileProvider.currentProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileProvider.currentProfile;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    profileProvider.errorMessage ?? 'Failed to load profile',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => profileProvider.fetchCurrentProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.blue.shade600, Colors.blue.shade400],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Edit Button in top-right corner
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => EditProfileScreen(profile: profile),
                                      ),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  tooltip: 'Edit Profile',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Profile Picture
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 56,
                                  backgroundColor: Colors.grey[300],
                                  backgroundImage: profile.profilePicture != null && profile.profilePicture!.isNotEmpty
                                      ? NetworkImage(profile.profilePicture!)
                                      : null,
                                  onBackgroundImageError: (error, stackTrace) {
                                    print('❌ Error loading profile image: $error');
                                    // Image will fall back to initials automatically
                                  },
                                  child: profile.profilePicture == null || profile.profilePicture!.isEmpty
                                      ? Text(
                                          profile.fullName.isNotEmpty
                                              ? profile.fullName[0].toUpperCase()
                                              : 'U',
                                          style: const TextStyle(
                                            fontSize: 40,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _showImagePickerDialog,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade700,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                              if (profileProvider.isLoading)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.fullName,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              profile.role.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Profile Information Cards
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Personal Information Card
                      _buildInfoCard(
                        title: 'Personal Information',
                        icon: Icons.person,
                        children: [
                          _buildInfoRow(Icons.email, 'Email', profile.email),
                          if (profile.phone != null)
                            _buildInfoRow(Icons.phone, 'Phone', profile.phone!),
                          if (profile.dateOfBirth != null)
                            _buildInfoRow(
                              Icons.cake,
                              'Date of Birth',
                              DateFormat('MMM dd, yyyy').format(profile.dateOfBirth!),
                            ),
                          if (profile.gender != null)
                            _buildInfoRow(Icons.person_outline, 'Gender', profile.gender!),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Gym Information Card
                      _buildInfoCard(
                        title: 'Gym Information',
                        icon: Icons.fitness_center,
                        children: [
                          if (profile.gymName != null)
                            _buildInfoRow(Icons.business, 'Gym Name', profile.decodedGymName),
                          if (profile.gymDescription != null)
                            _buildInfoRow(Icons.description, 'Description', profile.decodedGymDescription),
                          if (profile.gymEstablishedDate != null)
                            _buildInfoRow(
                              Icons.calendar_today,
                              'Established',
                              DateFormat('MMM dd, yyyy').format(profile.gymEstablishedDate!),
                            ),
                          if (profile.subscriptionPlan != null)
                            _buildInfoRow(Icons.subscriptions, 'Plan', profile.subscriptionPlan!.toUpperCase()),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Contact Information Card
                      if (profile.address != null)
                        _buildInfoCard(
                          title: 'Contact Information',
                          icon: Icons.location_on,
                          children: [
                            _buildInfoRow(Icons.home, 'Address', profile.address!),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Account Information Card
                      _buildInfoCard(
                        title: 'Account Information',
                        icon: Icons.settings,
                        children: [
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Member Since',
                            DateFormat('MMM dd, yyyy').format(profile.createdAt),
                          ),
                          _buildInfoRow(
                            profile.isActive ? Icons.check_circle : Icons.cancel,
                            'Status',
                            profile.isActive ? 'Active' : 'Inactive',
                            valueColor: profile.isActive ? Colors.green : Colors.red,
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Action Buttons
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => EditProfileScreen(profile: profile),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const ChangePasswordScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.lock),
                              label: const Text('Change Password'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _showLogoutDialog(),
                              icon: const Icon(Icons.logout, color: Colors.red),
                              label: const Text('Logout', style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
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
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted && _profileProvider != null) {
        final File imageFile = File(image.path);
        
        // Store old image URL for cache eviction
        final oldImageUrl = _profileProvider!.currentProfile?.profilePicture;
        
        print('🔄 Starting profile picture upload...');
        final success = await _profileProvider!.uploadProfilePicture(imageFile);
        
        if (success && mounted && _profileProvider != null) {
          print('✅ Upload successful, refreshing profile...');
          
          // Evict old image from cache if it exists
          if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
            imageCache.evict(NetworkImage(oldImageUrl));
            print('🗑️ Evicted old image from cache: $oldImageUrl');
          }
          
          // Force refresh the profile to get the updated image URL
          await _profileProvider!.fetchCurrentProfile();
          
          // Evict new image URL from cache to force reload
          final newImageUrl = _profileProvider!.currentProfile?.profilePicture;
          if (newImageUrl != null && newImageUrl.isNotEmpty) {
            imageCache.evict(NetworkImage(newImageUrl));
            print('🔄 Evicted new image from cache to force reload: $newImageUrl');
          }
          
          // Force rebuild to show updated image
          if (mounted) {
            setState(() {});
          }
        }
        
        if (mounted && _scaffoldMessenger != null) {
          _scaffoldMessenger!.showSnackBar(
            SnackBar(
              content: Text(
                success 
                  ? 'Profile picture updated successfully!'
                  : _profileProvider?.errorMessage ?? 'Failed to upload image',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && _scaffoldMessenger != null) {
        _scaffoldMessenger!.showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}