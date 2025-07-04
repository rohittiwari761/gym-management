import 'subscription_plan.dart';
import 'member.dart';

enum SubscriptionStatus { active, expired, suspended, pending }

class MemberSubscription {
  final int id;
  final int memberId;
  final int subscriptionPlanId;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final double amountPaid;
  final DateTime? paymentDate;
  final String? paymentMethod;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Related objects
  final SubscriptionPlan? subscriptionPlan;
  final Member? member;

  MemberSubscription({
    required this.id,
    required this.memberId,
    required this.subscriptionPlanId,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.amountPaid,
    this.paymentDate,
    this.paymentMethod,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionPlan,
    this.member,
  });

  factory MemberSubscription.fromJson(Map<String, dynamic> json) {
    return MemberSubscription(
      id: json['id'],
      memberId: json['member_id'],
      subscriptionPlanId: json['subscription_plan_id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SubscriptionStatus.pending,
      ),
      amountPaid: double.parse(json['amount_paid'].toString()),
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date']) 
          : null,
      paymentMethod: json['payment_method'],
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      subscriptionPlan: json['subscription_plan'] != null
          ? SubscriptionPlan.fromJson(json['subscription_plan'])
          : null,
      member: json['member'] != null
          ? Member.fromJson(json['member'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'subscription_plan_id': subscriptionPlanId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status.toString().split('.').last,
      'amount_paid': amountPaid,
      'payment_date': paymentDate?.toIso8601String(),
      'payment_method': paymentMethod,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == SubscriptionStatus.active;
  
  bool get isExpired => status == SubscriptionStatus.expired || 
                       DateTime.now().isAfter(endDate);
  
  bool get isExpiringSoon => !isExpired && 
                            DateTime.now().isAfter(endDate.subtract(const Duration(days: 7)));
  
  int get daysUntilExpiry => endDate.difference(DateTime.now()).inDays;
  
  String get formattedAmount => '₹${amountPaid.toStringAsFixed(2)}';
  
  String get statusDisplay {
    switch (status) {
      case SubscriptionStatus.active:
        return 'Active';
      case SubscriptionStatus.expired:
        return 'Expired';
      case SubscriptionStatus.suspended:
        return 'Suspended';
      case SubscriptionStatus.pending:
        return 'Pending';
    }
  }
}