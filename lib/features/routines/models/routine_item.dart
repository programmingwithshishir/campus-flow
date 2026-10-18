import 'dart:convert';
import 'package:flutter/material.dart';

class RoutineItem {
  const RoutineItem({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.days,
    this.isEnabled = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int hour;
  final int minute;
  final Set<int> days; // 1 = Monday, 7 = Sunday (matching DateTime.monday .. DateTime.sunday)
  final bool isEnabled;
  final DateTime createdAt;

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  String get timeString {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }

  static const Map<int, String> dayShortNames = {
    1: 'Mon',
    2: 'Tue',
    3: 'Wed',
    4: 'Thu',
    5: 'Fri',
    6: 'Sat',
    7: 'Sun',
  };

  static const Map<int, String> dayFullNames = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };

  String get daysSummary {
    if (days.isEmpty) return 'No reminder days';
    if (days.length == 7) return 'Every day';
    if (days.length == 5 &&
        days.contains(1) &&
        days.contains(2) &&
        days.contains(3) &&
        days.contains(4) &&
        days.contains(5)) {
      return 'Weekdays';
    }
    if (days.length == 2 && days.contains(6) && days.contains(7)) {
      return 'Weekends';
    }
    final sortedDays = days.toList()..sort();
    return sortedDays.map((d) => dayShortNames[d] ?? '').join(', ');
  }

  RoutineItem copyWith({
    String? id,
    String? name,
    int? hour,
    int? minute,
    Set<int>? days,
    bool? isEnabled,
    DateTime? createdAt,
  }) {
    return RoutineItem(
      id: id ?? this.id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      days: days ?? this.days,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'hour': hour,
      'minute': minute,
      'days': days.toList()..sort(),
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory RoutineItem.fromJson(Map<String, dynamic> json) {
    final rawDays = (json['days'] as List<dynamic>?) ?? [];
    return RoutineItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name']?.toString() ?? '',
      hour: (json['hour'] as num?)?.toInt() ?? 0,
      minute: (json['minute'] as num?)?.toInt() ?? 0,
      days: rawDays.map((e) => (e as num).toInt()).toSet(),
      isEnabled: json['isEnabled'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

String encodeRoutines(List<RoutineItem> routines) {
  return jsonEncode(routines.map((r) => r.toJson()).toList());
}

List<RoutineItem> decodeRoutines(String? jsonStr) {
  if (jsonStr == null || jsonStr.isEmpty) {
    return [];
  }
  try {
    final decoded = jsonDecode(jsonStr);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(RoutineItem.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}
