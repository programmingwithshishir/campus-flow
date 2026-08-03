import 'dart:convert';

import 'package:flutter/material.dart';

enum TaskPriority { high, medium, low }

extension TaskPriorityData on TaskPriority {
  String get label {
    return switch (this) {
      TaskPriority.high => 'High',
      TaskPriority.medium => 'Medium',
      TaskPriority.low => 'Low',
    };
  }

  Color get color {
    return switch (this) {
      TaskPriority.high => const Color(0xFFDC2626),
      TaskPriority.medium => const Color(0xFFD97706),
      TaskPriority.low => const Color(0xFF2563EB),
    };
  }

  int get sortWeight {
    return switch (this) {
      TaskPriority.high => 3,
      TaskPriority.medium => 2,
      TaskPriority.low => 1,
    };
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.priority,
    required this.createdAt,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final TaskPriority priority;
  final DateTime createdAt;
  final bool isCompleted;

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      priority: TaskPriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  TaskItem copyWith({
    String? id,
    String? title,
    TaskPriority? priority,
    DateTime? createdAt,
    bool? isCompleted,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

int compareTaskItems(TaskItem left, TaskItem right) {
  if (left.isCompleted != right.isCompleted) {
    return left.isCompleted ? 1 : -1;
  }

  final priorityComparison = right.priority.sortWeight.compareTo(left.priority.sortWeight);
  if (priorityComparison != 0) {
    return priorityComparison;
  }

  return left.createdAt.compareTo(right.createdAt);
}

List<TaskItem> sortTaskItems(List<TaskItem> tasks) {
  tasks.sort(compareTaskItems);
  return tasks;
}

String encodeTasks(List<TaskItem> tasks) {
  return jsonEncode(tasks.map((task) => task.toJson()).toList());
}

List<TaskItem> decodeTasks(String? encodedTasks) {
  if (encodedTasks == null || encodedTasks.isEmpty) {
    return [];
  }

  final decoded = jsonDecode(encodedTasks) as List<dynamic>;
  return decoded.map((item) => TaskItem.fromJson(item as Map<String, dynamic>)).toList();
}