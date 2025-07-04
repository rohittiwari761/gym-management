import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../services/gym_data_service.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<Payment> _payments = [];
  Map<String, double> _revenueAnalytics = {};
  List<Map<String, dynamic>> _monthlyPayments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Payment> get payments => _payments;
  Map<String, double> get revenueAnalytics => _revenueAnalytics;
  List<Map<String, dynamic>> get monthlyPayments => _monthlyPayments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  double get totalRevenue => _revenueAnalytics['total_revenue'] ?? 0.0;
  double get monthlyRevenue => _revenueAnalytics['monthly_revenue'] ?? 0.0;
  double get weeklyRevenue => _revenueAnalytics['weekly_revenue'] ?? 0.0;
  double get dailyRevenue => _revenueAnalytics['daily_revenue'] ?? 0.0;

  List<Payment> get todayPayments {
    final today = DateTime.now();
    return _payments.where((payment) {
      return payment.paymentDate.year == today.year &&
             payment.paymentDate.month == today.month &&
             payment.paymentDate.day == today.day;
    }).toList();
  }

  List<Payment> get completedPayments =>
      _payments.where((payment) => payment.status == PaymentStatus.completed).toList();

  Future<void> fetchPayments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('💰 PAYMENTS: Fetching payments...');
      _payments = await _paymentService.getPayments();
      print('✅ PAYMENTS: Loaded ${_payments.length} payments from Django backend');
      
      // Don't create mock data - use real backend data only
    } catch (e) {
      print('💥 PAYMENTS ERROR: $e');
      _errorMessage = e.toString();
      
      // Only use mock data if backend is completely unreachable (network error)
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection failed')) {
        print('🔌 PAYMENTS: Backend unreachable, using mock data');
        _createMockPayments();
      } else {
        print('🔌 PAYMENTS: Backend reachable but returned error - no mock data');
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('💰 REVENUE: Fetching real revenue analytics from Django backend...');
      final response = await _paymentService.getRevenueAnalytics();
      
      if (response['success'] == true) {
        _revenueAnalytics = response['data'] as Map<String, double>;
        print('✅ REVENUE: Loaded real analytics - Monthly: ₹${_revenueAnalytics['monthly_revenue']}, Daily: ₹${_revenueAnalytics['daily_revenue']}');
      } else {
        _errorMessage = response['message'] ?? 'Failed to fetch revenue analytics';
        print('❌ REVENUE ERROR: $_errorMessage');
        // Set empty analytics instead of mock data
        _revenueAnalytics = {
          'total_revenue': 0.0,
          'monthly_revenue': 0.0,
          'weekly_revenue': 0.0,
          'daily_revenue': 0.0,
        };
      }
    } catch (e) {
      print('💥 REVENUE ERROR: $e');
      _errorMessage = e.toString();
      // Set empty analytics on error instead of mock data
      _revenueAnalytics = {
        'total_revenue': 0.0,
        'monthly_revenue': 0.0,
        'weekly_revenue': 0.0,
        'daily_revenue': 0.0,
      };
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchMonthlyPayments({required int year}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _monthlyPayments = await _paymentService.getPaymentsByMonth(year: year);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createPayment({
    required int memberId,
    int? subscriptionPlanId,
    required double amount,
    required PaymentMethod method,
    String? transactionId,
    String? notes,
    DateTime? paymentDate,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payment = await _paymentService.createPayment(
        memberId: memberId,
        subscriptionPlanId: subscriptionPlanId,
        amount: amount,
        method: method,
        transactionId: transactionId,
        notes: notes,
        paymentDate: paymentDate,
      );

      _payments.insert(0, payment);
      
      // Refresh revenue analytics to update payment overview
      await fetchRevenueAnalytics();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _createMockPayments() {
    final gymDataService = GymDataService();
    final gymName = gymDataService.currentGymName ?? 'Sample Gym';
    
    print('💰 PAYMENTS: Creating mock payment data for gym: $gymName');
    
    final now = DateTime.now();
    final baseMockPayments = [
      Payment(
        id: 1,
        memberId: 1,
        amount: 1500.0,
        method: PaymentMethod.cash,
        status: PaymentStatus.completed,
        paymentDate: DateTime(now.year, now.month, now.day - 2),
        notes: 'Monthly membership fee',
        transactionId: 'TXN001',
        createdAt: DateTime(now.year, now.month, now.day - 2),
        updatedAt: DateTime(now.year, now.month, now.day - 2),
      ),
      Payment(
        id: 2,
        memberId: 2,
        amount: 2500.0,
        method: PaymentMethod.card,
        status: PaymentStatus.completed,
        paymentDate: DateTime(now.year, now.month, now.day - 1),
        notes: 'Quarterly membership',
        transactionId: 'TXN002',
        createdAt: DateTime(now.year, now.month, now.day - 1),
        updatedAt: DateTime(now.year, now.month, now.day - 1),
      ),
      Payment(
        id: 3,
        memberId: 3,
        amount: 800.0,
        method: PaymentMethod.upi,
        status: PaymentStatus.completed,
        paymentDate: now,
        notes: 'Basic monthly plan',
        transactionId: 'TXN003',
        createdAt: now,
        updatedAt: now,
      ),
      Payment(
        id: 4,
        memberId: 4,
        amount: 1200.0,
        method: PaymentMethod.card,
        status: PaymentStatus.pending,
        paymentDate: now,
        notes: 'Premium membership',
        transactionId: 'TXN004',
        createdAt: now,
        updatedAt: now,
      ),
      Payment(
        id: 5,
        memberId: 5,
        amount: 5000.0,
        method: PaymentMethod.card,
        status: PaymentStatus.completed,
        paymentDate: DateTime(now.year, now.month - 1, now.day),
        notes: 'Semi-annual membership',
        transactionId: 'TXN005',
        createdAt: DateTime(now.year, now.month - 1, now.day),
        updatedAt: DateTime(now.year, now.month - 1, now.day),
      ),
    ];
    
    // Use gym-specific data isolation with unique IDs
    final gymSpecificPayments = gymDataService.getGymSpecificMockData<Payment>(
      baseMockPayments,
      (payment, uniqueId) => Payment(
        id: uniqueId, // Each gym gets completely unique ID range
        memberId: uniqueId, // Links to gym-specific member IDs
        amount: payment.amount,
        method: payment.method,
        status: payment.status,
        paymentDate: payment.paymentDate,
        notes: '${payment.notes} (${gymName})',
        transactionId: 'TXN${uniqueId.toString().padLeft(4, '0')}',
        createdAt: payment.createdAt,
        updatedAt: payment.updatedAt,
        memberSubscriptionId: payment.memberSubscriptionId,
      ),
    );
    
    _payments = gymSpecificPayments;
    gymDataService.logDataAccess('payment records', gymSpecificPayments.length);
  }
  
  /// Clear all payment data and reset for new gym context
  void clearAllData() {
    print('🧹 PAYMENTS: Clearing all payment data for new gym context');
    _payments.clear();
    _revenueAnalytics.clear();
    _monthlyPayments.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
  
  /// Force refresh payment data for current gym
  Future<void> forceRefresh() async {
    print('🔄 PAYMENTS: Force refreshing payment data');
    clearAllData();
    await Future.wait([
      fetchPayments(),
      fetchRevenueAnalytics(),
    ]);
  }
}