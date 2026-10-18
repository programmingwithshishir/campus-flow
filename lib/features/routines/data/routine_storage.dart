import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widget_sync_service.dart';
import '../models/routine_item.dart';

class RoutineStorage {
  RoutineStorage._();

  static const MethodChannel _channel = MethodChannel('campus_flow.widget_sync');
  static const String _prefsKey = 'campus_flow_routines_data';

  static void setRoutineUpdateListener(VoidCallback onRoutineUpdated) {
    WidgetSyncService.addListener('onWidgetRoutineUpdated', onRoutineUpdated);
  }

  static Future<List<RoutineItem>> loadRoutines() async {
    // 1. Try MethodChannel first (Android SharedPreferences)
    try {
      final encoded = await _channel.invokeMethod<String>('loadRoutines');
      if (encoded != null && encoded.isNotEmpty && encoded != '[]') {
        return decodeRoutines(encoded);
      }
    } on MissingPluginException {
      // Not on native Android or plugin missing
    } catch (_) {}

    // 2. Fallback to shared_preferences package
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_prefsKey);
      if (data != null && data.isNotEmpty) {
        return decodeRoutines(data);
      }
    } catch (_) {}

    return [];
  }

  static Future<void> saveRoutines(List<RoutineItem> routines) async {
    final encoded = encodeRoutines(routines);

    // 1. Save via MethodChannel
    try {
      await _channel.invokeMethod<void>(
        'saveRoutines',
        {'routines': encoded},
      );
    } on MissingPluginException {
      // Ignored
    } catch (_) {}

    // 2. Save via shared_preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, encoded);
    } catch (_) {}
  }
}
