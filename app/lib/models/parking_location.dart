class ParkingLocation {
  final int id;
  final String name;
  final String area;
  final double latitude;
  final double longitude;
  final int totalSlots;
  final int availableSlots;
  final String? distance;
  final double pricePerHour;

  ParkingLocation({
    required this.id,
    required this.name,
    required this.area,
    required this.latitude,
    required this.longitude,
    required this.totalSlots,
    required this.availableSlots,
    this.distance,
    this.pricePerHour = 20.0,
  });

  factory ParkingLocation.fromJson(Map<String, dynamic> json) {
    return ParkingLocation(
      id: json['id'],
      name: json['name'],
      area: json['area'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      totalSlots: json['total_slots'] ?? 0,
      availableSlots: json['available_slots'] ?? 0,
      distance: json['distance'],
      pricePerHour: (json['price_per_hour'] ?? 20.0).toDouble(),
    );
  }
}

class LocationSuggestion {
  final String name;
  final String area;
  final String type;

  LocationSuggestion({
    required this.name,
    required this.area,
    required this.type,
  });

  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    return LocationSuggestion(
      name: json['name'],
      area: json['area'],
      type: json['type'],
    );
  }
}
