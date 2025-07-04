// Notification service temporarily disabled - requires flutter_local_notifications package
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/member_subscription.dart';

class NotificationService {
  // Placeholder implementation - notifications disabled until package is enabled
  static Future<void> initialize() async {
    // TODO: Initialize notifications when package is enabled
    print('Notification service: Package disabled');
  }

  static Future<void> showSubscriptionExpiryAlert({
    required int id,
    required String memberName,
    required int daysUntilExpiry,
  }) async {
    // TODO: Show notification when package is enabled
    print('Subscription alert for $memberName: $daysUntilExpiry days until expiry');
  }

  static Future<void> checkAndSendRenewalAlerts(
    List<MemberSubscription> subscriptions,
  ) async {
    for (final subscription in subscriptions) {
      if (subscription.isExpired || subscription.isExpiringSoon) {
        await showSubscriptionExpiryAlert(
          id: subscription.id,
          memberName: subscription.member?.user?.fullName ?? 'Member',
          daysUntilExpiry: subscription.daysUntilExpiry,
        );
      }
    }
  }
}