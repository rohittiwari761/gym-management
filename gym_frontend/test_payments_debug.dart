import 'package:flutter/material.dart';
import 'lib/security/jwt_manager.dart';
import 'lib/services/payment_service.dart';
import 'lib/providers/payment_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔍 DEBUG: Testing payments tab network issue...');
  
  // Test 1: Check if token is available
  print('\n=== TEST 1: Check Authentication Token ===');
  final token = await JWTManager.getAccessToken();
  print('Token available: ${token != null}');
  if (token != null) {
    print('Token length: ${token.length}');
    print('Token starts with: ${token.substring(0, 20)}...');
  }
  
  // Test 2: Test PaymentService directly
  print('\n=== TEST 2: Test PaymentService directly ===');
  try {
    final paymentService = PaymentService();
    final payments = await paymentService.getPayments();
    print('✅ PaymentService.getPayments() successful');
    print('Payments count: ${payments.length}');
  } catch (e) {
    print('❌ PaymentService.getPayments() failed: $e');
  }
  
  // Test 3: Test Revenue Analytics (working endpoint)
  print('\n=== TEST 3: Test Revenue Analytics (working endpoint) ===');
  try {
    final paymentService = PaymentService();
    final analytics = await paymentService.getRevenueAnalytics();
    print('✅ PaymentService.getRevenueAnalytics() successful');
    print('Analytics: $analytics');
  } catch (e) {
    print('❌ PaymentService.getRevenueAnalytics() failed: $e');
  }
  
  // Test 4: Test PaymentProvider
  print('\n=== TEST 4: Test PaymentProvider ===');
  try {
    final paymentProvider = PaymentProvider();
    await paymentProvider.fetchPayments();
    print('✅ PaymentProvider.fetchPayments() completed');
    print('Error message: ${paymentProvider.errorMessage}');
    print('Payments count: ${paymentProvider.payments.length}');
  } catch (e) {
    print('❌ PaymentProvider.fetchPayments() failed: $e');
  }
  
  print('\n🏁 DEBUG: Testing complete');
}