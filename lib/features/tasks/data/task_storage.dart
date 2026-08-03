import 'package:flutter/services.dart';

import '../models/task_item.dart';

class TaskStorage {
  TaskStorage._();

  static const MethodChannel _channel = MethodChannel('campus_flow.widget_sync');

  static void setTaskUpdateListener(VoidCallback onTaskUpdated) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetTaskUpdated') {
        onTaskUpdated();
      }
    });
  }

  static Future<List<TaskItem>> loadTasks() async {
    try {
      final encodedTasks = await _channel.invokeMethod<String>('loadTasks');
      return decodeTasks(encodedTasks);
    } on MissingPluginException {
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTasks(List<TaskItem> tasks) async {
    try {
      await _channel.invokeMethod<void>(
        'saveTasks',
        {'tasks': encodeTasks(tasks)},
      );
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }
}