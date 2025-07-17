// PDF generation temporarily disabled - requires pdf and printing packages
// PDF generation temporarily disabled - requires pdf and printing packages
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';
import '../models/payment.dart';
import '../models/member.dart';
import '../models/gym_owner.dart';
import '../security/secure_http_client.dart';
import 'offline_handler.dart';
import '../security/security_config.dart';

class PaymentService {
  final SecureHttpClient _httpClient = SecureHttpClient();

  Future<List<Payment>> getPayments() async {
    try {
      print('🌐 PAYMENT_SERVICE: Making GET request to payments/ endpoint...');
      
      // Add connection timeout handling
      final response = await _httpClient.get('payments/').timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('⏰ PAYMENT_SERVICE: Request timed out after 10 seconds');
          throw Exception('Request timed out. Please check your internet connection.');
        },
      );
      
      print('🌐 PAYMENT_SERVICE: Response received');
      print('  - Status Code: ${response.statusCode}');
      print('  - Is Success: ${response.isSuccess}');
      print('  - Data Type: ${response.data?.runtimeType}');
      print('  - Error Message: ${response.errorMessage}');

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
          print('📊 API: Received paginated response with ${responseData['count']} total payments');
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
          print('📊 API: Received direct list response with ${jsonList.length} payments');
        } else {
          print('❌ API: Unexpected response format: ${responseData?.runtimeType}');
          throw Exception('Unexpected response format');
        }
        
        print('✅ PAYMENT_SERVICE: Converting ${jsonList.length} JSON objects to Payment objects');
        return jsonList.map((json) => Payment.fromJson(json)).toList();
      } else {
        print('❌ PAYMENT_SERVICE: Request failed');
        
        // Handle specific error cases
        if (response.statusCode == 401) {
          throw Exception('Authentication expired. Please login again.');
        } else if (response.statusCode == 403) {
          throw Exception('Access denied. Please check your permissions.');
        } else if (response.statusCode == 404) {
          throw Exception('Payments service not found. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        }
        
        throw Exception(response.errorMessage ?? 'Failed to load payments');
      }
    } catch (e) {
      print('💥 PAYMENT_SERVICE: Exception caught: ${e.runtimeType}');
      print('💥 PAYMENT_SERVICE: Exception message: $e');
      
      SecurityConfig.logSecurityEvent('PAYMENTS_LOAD_ERROR', {
        'error': e.toString(),
      });
      
      // Handle different types of errors
      if (e.toString().contains('TimeoutException') || 
          e.toString().contains('timed out')) {
        throw Exception('Connection timeout. Please check your internet connection and try again.');
      }
      
      final errorResult = OfflineHandler.handleNetworkError(e);
      print('💥 PAYMENT_SERVICE: Throwing processed error: ${errorResult['message']}');
      throw Exception(errorResult['message']);
    }
  }

  Future<Payment> createPayment({
    required int memberId,
    int? subscriptionPlanId,
    required double amount,
    required PaymentMethod method,
    int membershipMonths = 1,
    String? transactionId,
    String? notes,
    DateTime? paymentDate,
  }) async {
    try {
      final response = await _httpClient.post('payments/', body: {
        'member': memberId,
        'subscription_plan': subscriptionPlanId,
        'amount': amount,
        'payment_method': method.toString().split('.').last,
        'transaction_id': transactionId,
        'membership_months': membershipMonths,
        'notes': notes,
        'payment_date': (paymentDate ?? DateTime.now()).toIso8601String(),
      });

      if (response.isSuccess && response.data != null) {
        return Payment.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception(response.errorMessage ?? 'Failed to create payment');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('PAYMENT_CREATE_ERROR', {
        'error': e.toString(),
        'memberId': memberId,
        'amount': amount,
      });
      final errorResult = OfflineHandler.handleNetworkError(e);
      throw Exception(errorResult['message']);
    }
  }

  Future<void> generateAndPrintInvoice({
    required Payment payment,
    required Member member,
    required GymOwner gymOwner,
    String? subscriptionPlanName,
  }) async {
    // PDF generation temporarily disabled - requires pdf and printing packages
    print('PDF Invoice generation disabled');
    print('Invoice for ${member.user?.fullName}: ${payment.formattedAmount}');
    
    // TODO: Implement PDF generation when packages are enabled
    throw UnimplementedError('PDF generation is temporarily disabled. Enable pdf and printing packages to use this feature.');
  }

  Future<Map<String, dynamic>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _httpClient.get('payments/revenue_analytics/');

      print('💰 REVENUE SERVICE - Success: ${response.isSuccess}');
      print('💰 REVENUE SERVICE - Data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'data': {
            'total_revenue': double.parse(data['total_revenue'].toString()),
            'monthly_revenue': double.parse(data['monthly_revenue'].toString()),
            'weekly_revenue': double.parse(data['weekly_revenue'].toString()),
            'daily_revenue': double.parse(data['daily_revenue'].toString()),
          }
        };
      } else {
        return {
          'success': false,
          'message': response.errorMessage ?? 'Failed to fetch revenue analytics'
        };
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('REVENUE_ANALYTICS_ERROR', {
        'error': e.toString(),
      });
      final errorResult = OfflineHandler.handleNetworkError(e);
      throw Exception(errorResult['message']);
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentsByMonth({
    required int year,
  }) async {
    try {
      final response = await _httpClient.get('payments/monthly/$year/');

      if (response.isSuccess && response.data != null) {
        // Handle Django pagination format: {"count": X, "results": [...]}
        final responseData = response.data;
        List<dynamic> jsonList;
        
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response from Django REST Framework
          jsonList = responseData['results'] as List<dynamic>;
          print('📊 API: Received paginated response with ${responseData['count']} monthly payments for year $year');
        } else if (responseData is List<dynamic>) {
          // Direct list response (fallback)
          jsonList = responseData;
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to fetch monthly payments');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('MONTHLY_PAYMENTS_ERROR', {
        'error': e.toString(),
        'year': year,
      });
      final errorResult = OfflineHandler.handleNetworkError(e);
      throw Exception(errorResult['message']);
    }
  }
}