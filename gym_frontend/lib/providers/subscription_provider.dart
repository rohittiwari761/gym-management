import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/subscription_plan.dart';
import '../models/member_subscription.dart';
import '../services/auth_service.dart';
import '../services/offline_handler.dart';
import '../security/security_config.dart';

class SubscriptionProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  List<SubscriptionPlan> _subscriptionPlans = [];
  List<MemberSubscription> _memberSubscriptions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SubscriptionPlan> get subscriptionPlans => _subscriptionPlans;
  List<MemberSubscription> get memberSubscriptions => _memberSubscriptions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<SubscriptionPlan> get activeSubscriptionPlans =>
      _subscriptionPlans.where((plan) => plan.isActive).toList();

  List<MemberSubscription> get activeSubscriptions =>
      _memberSubscriptions.where((sub) => sub.isActive).toList();

  List<MemberSubscription> get expiredSubscriptions =>
      _memberSubscriptions.where((sub) => sub.isExpired).toList();

  List<MemberSubscription> get expiringSubscriptions =>
      _memberSubscriptions.where((sub) => sub.isExpiringSoon).toList();

  Future<void> fetchSubscriptionPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${SecurityConfig.apiUrl}/subscription-plans/'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      print('🔄 FETCH PLANS - Status: ${response.statusCode}');
      print('🔄 FETCH PLANS - Response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔍 FETCH PLANS - Parsed response structure: ${responseData.runtimeType}');
        
        // Handle both direct array and paginated response formats
        List<dynamic> data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response format
          data = responseData['results'] as List<dynamic>;
          print('🔍 FETCH PLANS - Using paginated format with ${data.length} results');
        } else if (responseData is List<dynamic>) {
          // Direct array format
          data = responseData;
          print('🔍 FETCH PLANS - Using direct array format with ${data.length} items');
        } else {
          throw Exception('Unexpected response format: expected array or paginated object');
        }
        
        _subscriptionPlans = data.map((json) => SubscriptionPlan.fromJson(json)).toList();
        print('✅ Successfully fetched ${_subscriptionPlans.length} subscription plans');
      } else {
        throw Exception('Failed to fetch subscription plans: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ FETCH PLANS EXCEPTION: $e');
      print('❌ FETCH PLANS EXCEPTION TYPE: ${e.runtimeType}');
      
      // Handle JSON parsing errors specifically
      if (e.toString().contains('FormatException') || 
          e.toString().contains('type') ||
          e.toString().contains('Unexpected response format')) {
        _errorMessage = 'Server returned invalid data format. Please try again.';
        print('❌ FETCH PLANS: JSON parsing error detected');
      } else {
        final errorResult = OfflineHandler.handleNetworkError(e);
        _errorMessage = errorResult['message'];
      }
      print('❌ FETCH PLANS ERROR: $_errorMessage');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMemberSubscriptions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${SecurityConfig.apiUrl}/member-subscriptions/'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Handle both direct array and paginated response formats
        List<dynamic> data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response format
          data = responseData['results'] as List<dynamic>;
        } else if (responseData is List<dynamic>) {
          // Direct array format
          data = responseData;
        } else {
          throw Exception('Unexpected response format for member subscriptions');
        }
        
        _memberSubscriptions = data.map((item) => MemberSubscription.fromJson(item)).toList();
        print('✅ Successfully fetched ${_memberSubscriptions.length} member subscriptions');
      } else {
        _errorMessage = 'Failed to fetch member subscriptions';
      }
    } catch (e) {
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSubscriptionPlan({
    required String name,
    required String description,
    required double price,
    required int durationInMonths,
    required List<String> features,
    String? discountPercentage,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${SecurityConfig.apiUrl}/subscription-plans/'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'description': description,
          'price': price,
          'duration_value': durationInMonths,
          'duration_type': 'months',
          'features': features,
          'discount_percentage': double.tryParse(discountPercentage ?? '0') ?? 0.0,
          'is_active': true,
        }),
      ).timeout(const Duration(seconds: 30));

      print('🏷️ CREATE PLAN - Status: ${response.statusCode}');
      print('🏷️ CREATE PLAN - Response: ${response.body}');

      if (response.statusCode == 201) {
        final newPlan = SubscriptionPlan.fromJson(jsonDecode(response.body));
        _subscriptionPlans.add(newPlan);
        _isLoading = false;
        notifyListeners();
        print('✅ Subscription plan created successfully: ${newPlan.name}');
        return true;
      } else {
        // Parse error message from response
        String errorMsg = 'Failed to create subscription plan';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            final errors = <String>[];
            errorData.forEach((key, value) {
              if (value is List) {
                errors.add('$key: ${value.join(', ')}');
              } else {
                errors.add('$key: $value');
              }
            });
            errorMsg = errors.join(', ');
          }
        } catch (e) {
          errorMsg = 'Server error: ${response.statusCode}';
        }
        
        _errorMessage = errorMsg;
        print('❌ CREATE PLAN ERROR: $_errorMessage');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSubscriptionPlan(int planId, {
    String? name,
    String? description,
    double? price,
    int? durationInMonths,
    List<String>? features,
    String? discountPercentage,
    bool? isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final Map<String, dynamic> body = {};
      
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (price != null) body['price'] = price;
      if (durationInMonths != null) body['duration_in_months'] = durationInMonths;
      if (features != null) body['features'] = features;
      if (discountPercentage != null) body['discount_percentage'] = discountPercentage;
      if (isActive != null) body['is_active'] = isActive;

      final response = await http.patch(
        Uri.parse('${SecurityConfig.apiUrl}/subscription-plans/$planId/'),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final updatedPlan = SubscriptionPlan.fromJson(jsonDecode(response.body));
        final index = _subscriptionPlans.indexWhere((plan) => plan.id == planId);
        if (index != -1) {
          _subscriptionPlans[index] = updatedPlan;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update subscription plan';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> assignSubscriptionToMember({
    required int memberId,
    required int subscriptionPlanId,
    required DateTime startDate,
    required double amountPaid,
    String? paymentMethod,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final plan = _subscriptionPlans.firstWhere((p) => p.id == subscriptionPlanId);
      final endDate = DateTime(
        startDate.year,
        startDate.month + plan.durationInMonths,
        startDate.day,
      );

      final response = await http.post(
        Uri.parse('${SecurityConfig.apiUrl}/member-subscriptions/'),
        headers: headers,
        body: jsonEncode({
          'member_id': memberId,
          'subscription_plan_id': subscriptionPlanId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'amount_paid': amountPaid,
          'payment_method': paymentMethod,
          'notes': notes,
          'status': 'active',
          'payment_date': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final newSubscription = MemberSubscription.fromJson(jsonDecode(response.body));
        _memberSubscriptions.add(newSubscription);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to assign subscription';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> renewSubscription(int subscriptionId, {
    required double amountPaid,
    String? paymentMethod,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await _authService.getAuthHeaders();
      final subscription = _memberSubscriptions.firstWhere((s) => s.id == subscriptionId);
      final plan = _subscriptionPlans.firstWhere((p) => p.id == subscription.subscriptionPlanId);
      
      final newStartDate = DateTime.now();
      final newEndDate = DateTime(
        newStartDate.year,
        newStartDate.month + plan.durationInMonths,
        newStartDate.day,
      );

      final response = await http.patch(
        Uri.parse('${SecurityConfig.apiUrl}/member-subscriptions/$subscriptionId/'),
        headers: headers,
        body: jsonEncode({
          'start_date': newStartDate.toIso8601String(),
          'end_date': newEndDate.toIso8601String(),
          'amount_paid': amountPaid,
          'payment_method': paymentMethod,
          'notes': notes,
          'status': 'active',
          'payment_date': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final updatedSubscription = MemberSubscription.fromJson(jsonDecode(response.body));
        final index = _memberSubscriptions.indexWhere((s) => s.id == subscriptionId);
        if (index != -1) {
          _memberSubscriptions[index] = updatedSubscription;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to renew subscription';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      final errorResult = OfflineHandler.handleNetworkError(e);
      _errorMessage = errorResult['message'];
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Clear all subscription data for new gym context
  void clearAllData() {
    print('🧹 SUBSCRIPTIONS: Clearing all subscription data for new gym context');
    _subscriptionPlans.clear();
    _memberSubscriptions.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Force refresh subscription data for current gym
  Future<void> forceRefresh() async {
    print('🔄 SUBSCRIPTIONS: Force refreshing subscription data');
    clearAllData();
    await Future.wait([
      fetchSubscriptionPlans(),
      fetchMemberSubscriptions(),
    ]);
  }
}