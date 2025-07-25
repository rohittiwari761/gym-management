import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/keep_alive_service.dart';
import '../security/jwt_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedLanguage = 'English';
  String _selectedCurrency = 'INR (₹)';
  AuthProvider? _authProvider;

  final List<String> _languages = ['English', 'Hindi', 'Spanish', 'French'];
  final List<String> _currencies = ['INR (₹)', 'USD (\$)', 'EUR (€)', 'GBP (£)'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Safely get the provider reference during dependency changes
    _authProvider = Provider.of<AuthProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _authProvider = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Settings Section
          _buildSectionHeader('App Settings'),
          _buildSettingsCard([
            _buildSwitchTile(
              'Push Notifications',
              'Receive notifications for important updates',
              Icons.notifications,
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
            ),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return _buildSwitchTile(
                  'Dark Mode',
                  'Switch to dark theme',
                  Icons.dark_mode,
                  themeProvider.isDarkMode,
                  (value) => themeProvider.setDarkMode(value),
                );
              },
            ),
            _buildSwitchTile(
              'Biometric Authentication',
              'Use fingerprint or face unlock',
              Icons.fingerprint,
              _biometricEnabled,
              (value) => setState(() => _biometricEnabled = value),
            ),
          ]),

          const SizedBox(height: 20),

          // Localization Section
          _buildSectionHeader('Localization'),
          _buildSettingsCard([
            _buildDropdownTile(
              'Language',
              'App display language',
              Icons.language,
              _selectedLanguage,
              _languages,
              (value) => setState(() => _selectedLanguage = value!),
            ),
            _buildDropdownTile(
              'Currency',
              'Default currency display',
              Icons.currency_rupee,
              _selectedCurrency,
              _currencies,
              (value) => setState(() => _selectedCurrency = value!),
            ),
          ]),

          const SizedBox(height: 20),

          // Data & Privacy Section
          _buildSectionHeader('Data & Privacy'),
          _buildSettingsCard([
            _buildActionTile(
              'Export Data',
              'Download your gym data',
              Icons.download,
              () => _showExportDialog(),
            ),
            _buildActionTile(
              'Clear Cache',
              'Free up storage space',
              Icons.cleaning_services,
              () => _showClearCacheDialog(),
            ),
            _buildActionTile(
              'Privacy Policy',
              'View our privacy policy',
              Icons.privacy_tip,
              () => _showPrivacyPolicy(),
            ),
          ]),

          const SizedBox(height: 20),

          // Support Section
          _buildSectionHeader('Support & Feedback'),
          _buildSettingsCard([
            _buildActionTile(
              'Help & FAQ',
              'Get help and find answers',
              Icons.help,
              () => _showHelp(),
            ),
            _buildActionTile(
              'Contact Support',
              'Get in touch with our team',
              Icons.support_agent,
              () => _contactSupport(),
            ),
            _buildActionTile(
              'Rate App',
              'Rate us on the app store',
              Icons.star,
              () => _rateApp(),
            ),
            _buildActionTile(
              'Send Feedback',
              'Help us improve the app',
              Icons.feedback,
              () => _sendFeedback(),
            ),
          ]),

          const SizedBox(height: 20),

          // Server Connection Section
          _buildSectionHeader('Server Connection'),
          _buildKeepAliveStatusCard(),
          
          // Temporary debug section
          _buildSectionHeader('Debug Tools'),
          _buildSettingsCard([
            _buildActionTile(
              'Extract Token for Testing',
              'Copy auth token for Postman testing',
              Icons.content_copy,
              () => _extractTokenForTesting(),
            ),
          ]),

          const SizedBox(height: 20),

          // About Section
          _buildSectionHeader('About'),
          _buildSettingsCard([
            _buildInfoTile(
              'Version',
              '1.0.0 (Build 1)',
              Icons.info,
            ),
            _buildInfoTile(
              'Developer',
              'Gym Management Solutions',
              Icons.code,
            ),
            _buildActionTile(
              'Terms of Service',
              'Read our terms and conditions',
              Icons.description,
              () => _showTerms(),
            ),
          ]),

          const SizedBox(height: 20),

          // Danger Zone
          _buildSectionHeader('Account'),
          _buildSettingsCard([
            _buildActionTile(
              'Change Password',
              'Update your password',
              Icons.lock_reset,
              () => _showChangePassword(),
            ),
            _buildActionTile(
              'Logout',
              'Sign out of your account',
              Icons.logout,
              () => _showLogoutConfirmation(),
              textColor: Colors.red,
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKeepAliveStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.network_check, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Keep-Alive Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: Future.value(KeepAliveService().getStatus()),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final status = snapshot.data!;
                final isRunning = status['isRunning'] as bool? ?? false;
                final totalPings = status['totalPings'] as int? ?? 0;
                final successRate = status['successRate'] as double? ?? 0.0;
                final consecutiveFailures = status['consecutiveFailures'] as int? ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow('Status', isRunning ? 'Running' : 'Stopped', 
                        isRunning ? Colors.green : Colors.red),
                    const SizedBox(height: 8),
                    _buildStatusRow('Total Pings', totalPings.toString(), Colors.grey[600]!),
                    const SizedBox(height: 8),
                    _buildStatusRow('Success Rate', '${successRate.toStringAsFixed(1)}%', 
                        successRate > 80 ? Colors.green : successRate > 50 ? Colors.orange : Colors.red),
                    const SizedBox(height: 8),
                    _buildStatusRow('Consecutive Failures', consecutiveFailures.toString(),
                        consecutiveFailures > 3 ? Colors.red : Colors.grey[600]!),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final success = await KeepAliveService().pingNow();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success 
                                        ? 'Ping successful!' 
                                        : 'Ping failed. Server might be sleeping.'),
                                    backgroundColor: success ? Colors.green : Colors.red,
                                  ),
                                );
                                setState(() {}); // Refresh status
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ping error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: Icon(Icons.network_ping),
                            label: Text('Ping Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (isRunning) {
                                KeepAliveService().stop();
                              } else {
                                KeepAliveService().initialize();
                              }
                              setState(() {}); // Refresh status
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isRunning 
                                      ? 'Keep-alive service stopped' 
                                      : 'Keep-alive service started'),
                                ),
                              );
                            },
                            icon: Icon(isRunning ? Icons.stop : Icons.play_arrow),
                            label: Text(isRunning ? 'Stop' : 'Start'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isRunning ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'This service pings the server every 15 minutes to prevent it from sleeping and reduce network failures.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.blue,
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: DropdownButton<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        underline: Container(),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.blue),
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile(
    String title,
    String value,
    IconData icon,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('This will export all your gym data to a CSV file. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export started...')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will clear all cached data. The app may load slower initially. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showChangePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password updated successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (mounted && _authProvider != null) {
                await _authProvider!.logoutWithDataClear(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Privacy Policy...')),
    );
  }

  void _showTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Terms of Service...')),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Help Center...')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Support Chat...')),
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening App Store...')),
    );
  }

  void _sendFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening Feedback Form...')),
    );
  }

  Future<void> _extractTokenForTesting() async {
    try {
      final token = await JWTManager.getAccessToken();
      if (token != null) {
        print('🔑 CURRENT_TOKEN_FOR_POSTMAN: $token');
        print('📋 COPY THIS FOR POSTMAN:');
        print('Authorization: Token $token');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token logged to console. Check Flutter logs.'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        print('❌ No token found - user might not be logged in');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No token found - please login first')),
        );
      }
    } catch (e) {
      print('💥 Error extracting token: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error extracting token: $e')),
      );
    }
  }
}