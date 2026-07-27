class Vehicle {
  final int id;
  final String name;
  final String plateNumber;
  final String type;
  final int ownerId;

  Vehicle({
    required this.id,
    required this.name,
    required this.plateNumber,
    required this.type,
    required this.ownerId,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'],
      name: json['name'],
      plateNumber: json['plate_number'],
      type: json['type'],
      ownerId: json['owner_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'plate_number': plateNumber,
      'type': type,
      'owner_id': ownerId,
    };
  }
}
