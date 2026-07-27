import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/vehicle.dart';
import '../models/parking_slot.dart';
import '../models/booking.dart';
import '../models/subscription_plan.dart';
import '../models/user_subscription.dart';
import '../models/parking_location.dart';

class ApiService {
  // Use localhost for emulator, but for physical device use your PC's IP
  // Detect platform to use localhost or ngrok
  static String get baseUrl {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return 'http://localhost:8001';
    }
    return 'https://rosann-stereospecific-triradiately.ngrok-free.dev';
  }

  Future<String?> get token async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, String>> get _headers async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true', // Required to bypass ngrok warning page
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Login failed');
    }
  }

  Future<void> requestAuthOtp(String email, {String type = 'login'}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'type': type}),
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> loginWithOtp(String email, String otp, {String? password}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email, 
        'otp': otp,
        if (password != null) 'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Verification failed');
    }
  }

  Future<Map<String, dynamic>> signupWithOtp({
    required String name,
    required String email,
    required String phone,
    required String otp,
    required String password,
    String? licenceNo,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'otp': otp,
        'password': password,
        'licence_no': licenceNo,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['token']['access_token']);
      return data;
    } else {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Signup failed');
    }
  }

  Future<void> signup(String name, String email, String phone, String password, String licenceNo) async {
    final response = await http.post(
      Uri.parse('$baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'licence_no': licenceNo,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Signup failed');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to request OTP');
    }
  }

  Future<void> verifyOTP(String email, String otp) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Invalid OTP');
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'new_password': newPassword
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Failed to reset password');
    }
  }

  Future<User> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch profile');
    }
  }

  // Vehicles
  Future<List<Vehicle>> getVehicles() async {
    final response = await http.get(
      Uri.parse('$baseUrl/vehicles/'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((v) => Vehicle.fromJson(v)).toList();
    } else {
      throw Exception('Failed to load vehicles');
    }
  }

  Future<Vehicle> addVehicle(Map<String, dynamic> vehicleData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vehicles/'),
      headers: await _headers,
      body: jsonEncode(vehicleData),
    );

    if (response.statusCode == 200) {
      return Vehicle.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add vehicle');
    }
  }

  Future<void> deleteVehicle(int vehicleId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/vehicles/$vehicleId'),
        headers: await _headers,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        String detail = 'Unexpected error';
        try {
          final error = jsonDecode(response.body);
          detail = error['detail'] ?? 'No detail provided';
        } catch (_) {}
        throw Exception('Server Error (${response.statusCode}): $detail');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Network error: Please check your internet or ngrok status.');
      }
      rethrow;
    }
  }

  // Slots
  Future<List<ParkingSlot>> getSlots(String? type, {String? location}) async {
    var url = '$baseUrl/slots/';
    List<String> params = [];
    if (type != null) params.add('type=$type');
    if (location != null && location != 'All') params.add('location=$location');
    
    if (params.isNotEmpty) {
      url += '?' + params.join('&');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((s) => ParkingSlot.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load slots');
    }
  }

  Future<List<ParkingSlot>> getSlotsByLocationId(int locationId, {String? type}) async {
    var url = '$baseUrl/slots/?location_id=$locationId';
    if (type != null) url += '&type=$type';

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((s) => ParkingSlot.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load slots for location');
    }
  }

  // Locations
  Future<List<LocationSuggestion>> getSuggestions(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/locations/suggestions?q=$query'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((s) => LocationSuggestion.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load suggestions');
    }
  }

  Future<List<ParkingLocation>> getNearbyParking(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/locations/nearby?q=$query'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((l) => ParkingLocation.fromJson(l)).toList();
    } else {
      throw Exception('Failed to load nearby parking');
    }
  }

  // Bookings
  Future<Booking> createBooking(int slotId, int vehicleId, DateTime startTime, DateTime endTime, String paymentMethod) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings/'),
      headers: await _headers,
      body: jsonEncode({
        'slot_id': slotId,
        'vehicle_id': vehicleId,
        'start_time': startTime.toUtc().toIso8601String(),
        'end_time': endTime.toUtc().toIso8601String(),
        'payment_method': paymentMethod,
      }),
    );

    if (response.statusCode == 200) {
      return Booking.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Booking failed');
    }
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bookings/my'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((b) => Booking.fromJson(b)).toList();
    } else {
      throw Exception('Failed to load history');
    }
  }

  Future<void> cancelBooking(int bookingId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      headers: await _headers,
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Cancellation failed');
    }
  }

  // Wallet
  Future<User> addMoney(double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/add-money?amount=$amount'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to add money');
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/'),
      headers: await _headers,
    );

    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markAllNotificationsRead() async {
    final response = await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: await _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications as read');
    }
  }

  // Contact
  Future<void> submitContact(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contact'),
      headers: await _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit message');
    }
  }

  Future<User> updateUserMe(String name, String phone, String licenceNo) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/me'),
      headers: await _headers,
      body: jsonEncode({
        'name': name, 
        'phone': phone,
        'licence_no': licenceNo
      }),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // Admin
  Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load admin stats');
    }
  }

  Future<List<User>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((u) => User.fromJson(u)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<List<ParkingSlot>> getAllSlots() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/slots'),
      headers: await _headers,
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((s) => ParkingSlot.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load all slots');
    }
  }

  Future<void> updateSlot(int slotId, bool isAvailable) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/slots/$slotId'),
      headers: await _headers,
      body: jsonEncode({'is_available': isAvailable}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update slot');
    }
  }

  Future<void> deleteUser(int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: await _headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  // --- SUBSCRIPTIONS ---
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    final response = await http.get(Uri.parse('$baseUrl/subscriptions/plans'), headers: await _headers);
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => SubscriptionPlan.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subscription plans');
    }
  }

  Future<List<UserSubscription>> getMySubscriptions() async {
    final response = await http.get(Uri.parse('$baseUrl/subscriptions/my'), headers: await _headers);
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => UserSubscription.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load subscriptions');
    }
  }

  Future<void> purchaseSubscription(int planId, String paymentMethod) async {
    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions/purchase'),
      headers: await _headers,
      body: jsonEncode({
        'plan_id': planId,
        'payment_method': paymentMethod,
      })
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['detail'] ?? 'Failed to purchase subscription');
    }
  }
}
