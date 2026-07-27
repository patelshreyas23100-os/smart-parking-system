import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token != null) {
      try {
        _user = await _apiService.getMe();
        _isAuthenticated = true;
      } catch (e) {
        await prefs.remove('access_token');
        _isAuthenticated = false;
      }
    }
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.login(email, password);
      _user = await _apiService.getMe();
      _isAuthenticated = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestOtp(String email, {String type = 'login'}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.requestAuthOtp(email, type: type);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithOtp(String email, String otp, String? password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.loginWithOtp(email, otp, password: password);
      _user = await _apiService.getMe();
      _isAuthenticated = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signupWithOtp({
    required String name,
    required String email,
    required String phone,
    required String otp,
    required String password,
    String? licenceNo,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.signupWithOtp(
        name: name,
        email: email,
        phone: phone,
        otp: otp,
        password: password,
        licenceNo: licenceNo,
      );
      
      _user = User.fromJson(data['user']);
      _isAuthenticated = true;
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signup(String name, String email, String phone, String password, String licenceNo) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.signup(name, email, phone, password, licenceNo);
      await login(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }
}
