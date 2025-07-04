import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../providers/trainer_provider.dart';
import '../providers/equipment_provider.dart';
import '../providers/payment_provider.dart';
import '../models/payment.dart';
import '../security/security_config.dart';
import '../security/jwt_manager.dart';
import '../services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugOutput = '';
  bool _isLoading = false;

  void _addDebugLine(String line) {
    setState(() {
      _debugOutput += '$line\n';
    });
  }

  Future<void> _clearTokens() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      _addDebugLine('🗑️ Clearing all cached tokens...');
      await JWTManager.clearTokens();
      _addDebugLine('✅ Tokens cleared successfully');
      
      // Also clear auth provider state
      if (mounted) {
        await context.read<AuthProvider>().logout();
        _addDebugLine('✅ Auth provider state cleared');
      }
    } catch (e) {
      _addDebugLine('❌ Error clearing tokens: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testConnectivity() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      _addDebugLine('🔧 CONNECTIVITY TEST: Starting...');
      _addDebugLine('🔧 API URL: ${SecurityConfig.apiUrl}');
      
      // Test 1: Basic connection
      _addDebugLine('\n📡 Test 1: Basic API connection...');
      final response = await http.get(
        Uri.parse('${SecurityConfig.apiUrl}/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 10));
      
      _addDebugLine('✅ Response Status: ${response.statusCode}');
      final body = response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body;
      _addDebugLine('✅ Response Body: $body');
      
      // Test 2: Login test
      _addDebugLine('\n📡 Test 2: Login test...');
      final loginResponse = await http.post(
        Uri.parse('${SecurityConfig.apiUrl}/auth/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': 'admin@gym.com',
          'password': 'password123'
        }),
      ).timeout(Duration(seconds: 10));
      
      _addDebugLine('✅ Login Status: ${loginResponse.statusCode}');
      
      if (loginResponse.statusCode == 200) {
        final loginData = jsonDecode(loginResponse.body);
        final token = loginData['token'];
        
        // Test 3: Authenticated endpoint
        _addDebugLine('\n📡 Test 3: Members endpoint with auth...');
        final membersResponse = await http.get(
          Uri.parse('${SecurityConfig.apiUrl}/members/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        ).timeout(Duration(seconds: 10));
        
        _addDebugLine('✅ Members Status: ${membersResponse.statusCode}');
        final membersData = jsonDecode(membersResponse.body);
        _addDebugLine('✅ Members Count: ${membersData.length}');
      } else {
        _addDebugLine('❌ Login failed');
      }
      
      _addDebugLine('\n🎉 CONNECTIVITY TEST COMPLETED!');
      
    } catch (e) {
      _addDebugLine('❌ CONNECTIVITY TEST FAILED: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testProviders() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      _addDebugLine('🔧 PROVIDER TEST: Starting...');
      
      // Test AuthProvider login
      _addDebugLine('\n📡 Test 1: AuthProvider login...');
      final authProvider = context.read<AuthProvider>();
      final loginResult = await authProvider.login('admin@gym.com', 'password123');
      
      if (loginResult['success'] == true) {
        _addDebugLine('✅ AuthProvider login successful');
        _addDebugLine('✅ Is logged in: ${authProvider.isLoggedIn}');
        _addDebugLine('✅ User: ${authProvider.user?.email}');
        
        // Test MemberProvider
        _addDebugLine('\n📡 Test 2: MemberProvider fetch...');
        final memberProvider = context.read<MemberProvider>();
        await memberProvider.fetchMembers();
        _addDebugLine('✅ Members loaded: ${memberProvider.members.length}');
        _addDebugLine('✅ Error: ${memberProvider.errorMessage ?? 'None'}');
        
        // Test TrainerProvider
        _addDebugLine('\n📡 Test 3: TrainerProvider fetch...');
        final trainerProvider = context.read<TrainerProvider>();
        await trainerProvider.fetchTrainers();
        _addDebugLine('✅ Trainers loaded: ${trainerProvider.trainers.length}');
        _addDebugLine('✅ Error: ${trainerProvider.errorMessage ?? 'None'}');
        
        // Test EquipmentProvider
        _addDebugLine('\n📡 Test 4: EquipmentProvider fetch...');
        final equipmentProvider = context.read<EquipmentProvider>();
        await equipmentProvider.fetchEquipment();
        _addDebugLine('✅ Equipment loaded: ${equipmentProvider.equipment.length}');
        _addDebugLine('✅ Error: ${equipmentProvider.errorMessage ?? 'None'}');
        
      } else {
        _addDebugLine('❌ AuthProvider login failed: ${loginResult['error']}');
      }
      
      _addDebugLine('\n🎉 PROVIDER TEST COMPLETED!');
      
    } catch (e) {
      _addDebugLine('❌ PROVIDER TEST FAILED: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testPaymentCreation() async {
    setState(() {
      _isLoading = true;
      _debugOutput = '';
    });

    try {
      _addDebugLine('💰 PAYMENT TEST: Starting...');
      
      // Check current authentication
      final authProvider = context.read<AuthProvider>();
      _addDebugLine('📋 Current user: ${authProvider.user?.email ?? 'Not logged in'}');
      _addDebugLine('📋 Is logged in: ${authProvider.isLoggedIn}');
      
      if (!authProvider.isLoggedIn) {
        _addDebugLine('❌ Not logged in - please login first');
        return;
      }
      
      // Check authentication token
      final token = await JWTManager.getAccessToken();
      _addDebugLine('🔑 Token available: ${token != null}');
      if (token != null) {
        _addDebugLine('🔑 Token preview: ${token.substring(0, 20)}...');
      }
      
      // Test member fetch first
      _addDebugLine('\n📡 Test 1: Fetching members...');
      final memberProvider = context.read<MemberProvider>();
      await memberProvider.fetchMembers();
      _addDebugLine('✅ Members loaded: ${memberProvider.members.length}');
      
      if (memberProvider.members.isEmpty) {
        _addDebugLine('❌ No members found - cannot test payment creation');
        return;
      }
      
      final firstMember = memberProvider.members.first;
      _addDebugLine('✅ Using member: ${firstMember.user?.fullName} (ID: ${firstMember.id})');
      
      // Test payment creation
      _addDebugLine('\n💰 Test 2: Creating test payment...');
      final paymentProvider = context.read<PaymentProvider>();
      
      try {
        final success = await paymentProvider.createPayment(
          memberId: firstMember.id!,
          amount: 1500.0,
          method: PaymentMethod.cash,
          notes: 'Debug test payment',
        );
        
        if (success) {
          _addDebugLine('✅ Payment created successfully!');
          _addDebugLine('✅ Total payments: ${paymentProvider.payments.length}');
          await paymentProvider.fetchRevenueAnalytics();
          _addDebugLine('✅ Revenue analytics updated');
        } else {
          _addDebugLine('❌ Payment creation failed: ${paymentProvider.errorMessage}');
        }
      } catch (e) {
        _addDebugLine('❌ Payment creation error: $e');
      }
      
      _addDebugLine('\n🎉 PAYMENT TEST COMPLETED!');
      
    } catch (e) {
      _addDebugLine('❌ PAYMENT TEST FAILED: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Connectivity'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Control buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _clearTokens,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Clear Tokens'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _testConnectivity,
                        icon: const Icon(Icons.network_check),
                        label: const Text('Test Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testProviders,
                    icon: const Icon(Icons.settings),
                    label: const Text('Test Providers'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _testPaymentCreation,
                    icon: const Icon(Icons.payment),
                    label: const Text('Test Payment Creation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'API URL: ${SecurityConfig.apiUrl}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Debug output
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey),
              ),
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Running tests...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _debugOutput.isEmpty 
                            ? 'Tap a button above to run tests...' 
                            : _debugOutput,
                        style: const TextStyle(
                          color: Colors.green,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}