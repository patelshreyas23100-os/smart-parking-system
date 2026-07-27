import 'subscription_plan.dart';

class UserSubscription {
  final int id;
  final int userId;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime endDate;
  final String status;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.plan,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'],
      userId: json['user_id'],
      plan: SubscriptionPlan.fromJson(json['plan']),
      startDate: DateTime.parse(json['start_date'] + 'Z').toLocal(),
      endDate: DateTime.parse(json['end_date'] + 'Z').toLocal(),
      status: json['status'],
    );
  }
}
