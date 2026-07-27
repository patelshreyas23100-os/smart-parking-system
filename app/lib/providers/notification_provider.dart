import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final _apiService = ApiService();
  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchUnreadCount() async {
    _isLoading = true;
    notifyListeners();
    try {
      final notifications = await _apiService.getNotifications();
      _unreadCount = notifications.where((n) => n['is_read'] == false).length;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsRead();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }
}
