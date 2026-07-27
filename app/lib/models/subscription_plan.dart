class SubscriptionPlan {
  final int id;
  final String name;
  final String vehicleType;
  final int durationDays;
  final double price;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.vehicleType,
    required this.durationDays,
    required this.price,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'],
      name: json['name'],
      vehicleType: json['vehicle_type'],
      durationDays: json['duration_days'],
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}
