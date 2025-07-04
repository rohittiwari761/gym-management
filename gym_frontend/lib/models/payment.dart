import 'member.dart';

enum PaymentStatus { pending, completed, failed, refunded }
enum PaymentMethod { cash, card, upi, bankTransfer }

class Payment {
  final int id;
  final int memberId;
  final int? memberSubscriptionId;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final String? transactionId;
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Member? member; // Add member object for display

  Payment({
    required this.id,
    required this.memberId,
    this.memberSubscriptionId,
    required this.amount,
    required this.status,
    required this.method,
    this.transactionId,
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.member,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      memberId: json['member'] is Map ? json['member']['id'] : json['member'],
      memberSubscriptionId: json['subscription_plan'] != null 
          ? json['subscription_plan']['id'] 
          : null,
      amount: double.parse(json['amount'].toString()),
      status: PaymentStatus.completed, // Default to completed as Django doesn't seem to track status
      method: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      transactionId: json['transaction_id'],
      paymentDate: DateTime.parse(json['payment_date']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : DateTime.parse(json['created_at']), // Fallback to created_at if updated_at is null
      member: json['member'] != null ? Member.fromJson(json['member']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'member_subscription_id': memberSubscriptionId,
      'amount': amount,
      'status': status.toString().split('.').last,
      'method': method.toString().split('.').last,
      'transaction_id': transactionId,
      'payment_date': paymentDate.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
  
  String get statusDisplay {
    switch (status) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.refunded:
        return 'Refunded';
    }
  }
  
  String get methodDisplay {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
    }
  }
}