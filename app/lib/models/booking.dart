import 'user.dart';
import 'vehicle.dart';
import 'parking_slot.dart';

class Booking {
  final int id;
  final int userId;
  final int slotId;
  final int vehicleId;
  final DateTime startTime;
  final DateTime endTime;
  final double totalPrice;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final String? locationDetail;
  final ParkingSlot? slot;
  final Vehicle? vehicle;

  Booking({
    required this.id,
    required this.userId,
    required this.slotId,
    required this.vehicleId,
    required this.startTime,
    required this.endTime,
    required this.totalPrice,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    this.locationDetail,
    this.slot,
    this.vehicle,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      slotId: json['slot_id'],
      vehicleId: json['vehicle_id'],
      startTime: _parseUtc(json['start_time']),
      endTime: _parseUtc(json['end_time']),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      status: json['status'],
      paymentMethod: json['payment_method'],
      createdAt: _parseUtc(json['created_at']),
      locationDetail: json['location_detail'],
      slot: json['slot'] != null ? ParkingSlot.fromJson(json['slot']) : null,
      vehicle: json['vehicle'] != null ? Vehicle.fromJson(json['vehicle']) : null,
    );
  }

  static DateTime _parseUtc(String dateStr) {
    if (!dateStr.contains('Z') && !dateStr.contains('+')) {
      dateStr += 'Z';
    }
    return DateTime.parse(dateStr).toLocal();
  }
}
