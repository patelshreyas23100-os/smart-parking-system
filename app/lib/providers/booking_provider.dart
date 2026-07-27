import 'package:flutter/material.dart';
import '../models/parking_slot.dart';
import '../models/vehicle.dart';
import '../models/booking.dart';
import '../services/api_service.dart';

class BookingProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  String? _selectedLocation;
  String? _selectedVehicleType;
  Vehicle? _selectedVehicle;
  ParkingSlot? _selectedSlot;
  DateTime? _startTime;
  DateTime? _endTime;
  String? _paymentMethod;
  bool _isBooking = false;
  Booking? _lastBooking;

  String? get selectedLocation => _selectedLocation;
  String? get selectedVehicleType => _selectedVehicleType;
  Vehicle? get selectedVehicle => _selectedVehicle;
  ParkingSlot? get selectedSlot => _selectedSlot;
  DateTime? get startTime => _startTime;
  DateTime? get endTime => _endTime;
  String? get paymentMethod => _paymentMethod;
  bool get isBooking => _isBooking;
  Booking? get lastBooking => _lastBooking;

  void setLocation(String location) {
    _selectedLocation = location;
    notifyListeners();
  }

  void setVehicleType(String type) {
    _selectedVehicleType = type;
    notifyListeners();
  }

  void setVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  void setSlot(ParkingSlot slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  void setTimes(DateTime start, DateTime end) {
    _startTime = start;
    _endTime = end;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  Future<Booking> confirmBooking() async {
    if (_selectedSlot == null || _selectedVehicle == null || _startTime == null || _endTime == null || _paymentMethod == null) {
      throw Exception('Incomplete booking details');
    }
    
    _isBooking = true;
    notifyListeners();
    
    try {
      final booking = await _apiService.createBooking(
        _selectedSlot!.id,
        _selectedVehicle!.id,
        _startTime!,
        _endTime!,
        _paymentMethod!,
      );
      _lastBooking = booking;
      reset();
      return booking;
    } finally {
      _isBooking = false;
      notifyListeners();
    }
  }

  void reset() {
    _selectedLocation = null;
    _selectedVehicleType = null;
    _selectedVehicle = null;
    _selectedSlot = null;
    _startTime = null;
    _endTime = null;
    _paymentMethod = null;
    notifyListeners();
  }
}
