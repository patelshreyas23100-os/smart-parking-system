class ParkingSlot {
  final int id;
  final String slotNumber;
  final String type;
  final String location;
  final bool isAvailable;
  final double pricePerHour;

  final int? locationId;

  ParkingSlot({
    required this.id,
    required this.slotNumber,
    required this.type,
    required this.location,
    required this.isAvailable,
    required this.pricePerHour,
    this.locationId,
  });

  factory ParkingSlot.fromJson(Map<String, dynamic> json) {
    return ParkingSlot(
      id: json['id'],
      slotNumber: json['slot_number'],
      type: json['type'],
      location: json['location'] ?? 'General',
      isAvailable: json['is_available'],
      pricePerHour: (json['price_per_hour'] ?? 0.0).toDouble(),
      locationId: json['location_id'],
    );
  }
}
