import 'package:flutter/material.dart';
import '../services/backup_service.dart';
import '../services/notification_service.dart';

class SettingsViewModel extends ChangeNotifier {
  final BackupService _backupService = BackupService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  ThemeMode _themeMode = ThemeMode.system;
  bool _notificationsEnabled = true;
  int _reminderTimeOffset = 15; // in minutes
  bool _isBackingUp = false;
  bool _isRestoring = false;
  String? _errorMessage;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get notificationsEnabled => _notificationsEnabled;
  int get reminderTimeOffset => _reminderTimeOffset;
  bool get isBackingUp => _isBackingUp;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;

  // Toggle Theme Mode
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Toggle Notifications
  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    if (!enabled) {
      await _notificationService.cancelAllNotifications();
    } else {
      // Re-request permissions just in case
      await _notificationService.requestPermissions();
    }
    notifyListeners();
  }

  // Set Reminder Warning Offset (e.g. 5, 10, 15, 30 minutes before)
  void setReminderTimeOffset(int minutes) {
    _reminderTimeOffset = minutes;
    notifyListeners();
  }

  // Backup Data Action
  Future<bool> backupData() async {
    _isBackingUp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _backupService.exportData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  // Restore Data Action
  Future<bool> restoreData() async {
    _isRestoring = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _backupService.restoreData();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
