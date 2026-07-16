import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_config.dart';
import 'supabase_service.dart';

class MaintenanceService {
  static final MaintenanceService instance = MaintenanceService._internal();
  MaintenanceService._internal();

  final SupabaseService _db = SupabaseService.instance;
  static const String _cacheFileName = 'app_config_cache.json';

  Future<File> get _cacheFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_cacheFileName');
  }

  /// Fetches config from Supabase, updates cache on success.
  /// If fails, returns cached config (if any) or null.
  Future<AppConfig?> fetchConfig() async {
    try {
      final data = await _db.client
          .from('app_config')
          .select()
          .eq('id', 'maintenance')
          .maybeSingle();

      if (data != null) {
        final config = AppConfig.fromJson(data);
        await _cacheConfig(data);
        return config;
      }
    } catch (e) {
      debugPrint("Failed to fetch maintenance config from remote: $e");
    }

    // Try loading from cache if remote fetch fails
    return await _getCachedConfig();
  }

  /// Caches the config JSON to local storage.
  Future<void> _cacheConfig(Map<String, dynamic> data) async {
    try {
      final file = await _cacheFile;
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("Failed to cache maintenance config: $e");
    }
  }

  /// Reads cached config from local storage.
  Future<AppConfig?> _getCachedConfig() async {
    try {
      final file = await _cacheFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        return AppConfig.fromJson(data);
      }
    } catch (e) {
      debugPrint("Failed to read cached maintenance config: $e");
    }
    return null;
  }
}
