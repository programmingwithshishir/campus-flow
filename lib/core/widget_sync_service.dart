import 'package:flutter/services.dart';

class WidgetSyncService {
  WidgetSyncService._();

  static const MethodChannel channel = MethodChannel('campus_flow.widget_sync');
  static final Map<String, List<VoidCallback>> _listeners = {};
  static bool _initialized = false;

  static void addListener(String method, VoidCallback callback) {
    _ensureInitialized();
    final list = _listeners.putIfAbsent(method, () => []);
    if (!list.contains(callback)) {
      list.add(callback);
    }
  }

  static void removeListener(String method, VoidCallback callback) {
    _listeners[method]?.remove(callback);
  }

  static void _ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    channel.setMethodCallHandler((call) async {
      final callbacks = _listeners[call.method];
      if (callbacks != null) {
        for (final cb in List.of(callbacks)) {
          cb();
        }
      }
    });
  }
}
