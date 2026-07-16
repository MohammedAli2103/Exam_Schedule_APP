import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/maintenance_service.dart';
import '../utils/constants.dart';

class MaintenanceViewModel extends ChangeNotifier {
  final MaintenanceService _service = MaintenanceService.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AppConfig? _config;
  AppConfig? get config => _config;

  bool _isMaintenanceActive = false;
  bool get isMaintenanceActive => _isMaintenanceActive;

  bool _isForceUpdateActive = false;
  bool get isForceUpdateActive => _isForceUpdateActive;

  String get currentVersion => AppConstants.appVersion;

  /// Runs the maintenance check.
  Future<void> checkMaintenance() async {
    _isLoading = true;
    notifyListeners();

    try {
      final remoteConfig = await _service.fetchConfig();
      if (remoteConfig != null) {
        _config = remoteConfig;
        
        // 1. Check if maintenance is enabled
        if (remoteConfig.maintenanceEnabled) {
          _isMaintenanceActive = true;
        } else {
          _isMaintenanceActive = false;
          
          // 2. Check for optional force update
          if (remoteConfig.forceUpdate) {
            final hasNewerVersion = _compareVersion(currentVersion, remoteConfig.latestVersion) < 0;
            _isForceUpdateActive = hasNewerVersion;
          } else {
            _isForceUpdateActive = false;
          }
        }
      } else {
        // Fallback: If we couldn't fetch anything (remote is null and cache is null),
        // we continue normally.
        _isMaintenanceActive = false;
        _isForceUpdateActive = false;
      }
    } catch (e) {
      debugPrint("Error checking maintenance: $e");
      // Continue normally
      _isMaintenanceActive = false;
      _isForceUpdateActive = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Version comparator: returns -1 if v1 < v2, 1 if v1 > v2, 0 if v1 == v2
  int _compareVersion(String v1, String v2) {
    final v1Parts = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final v2Parts = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    
    final maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    for (var i = 0; i < maxLength; i++) {
      final v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final v2Part = i < v2Parts.length ? v2Parts[i] : 0;
      
      if (v1Part < v2Part) return -1;
      if (v1Part > v2Part) return 1;
    }
    return 0;
  }
}
