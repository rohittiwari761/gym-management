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
      final response = await _httpClient.get('payments/');

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
        } else {
          throw Exception('Unexpected response format');
        }
        
        return jsonList.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception(response.errorMessage ?? 'Failed to load payments');
      }
    } catch (e) {
      SecurityConfig.logSecurityEvent('PAYMENTS_LOAD_ERROR', {
        'error': e.toString(),
      });
      final errorResult = OfflineHandler.handleNetworkError(e);
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