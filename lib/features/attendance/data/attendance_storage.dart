import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/absence_record.dart';

class AttendanceData {
  const AttendanceData({
    required this.subjects,
    required this.records,
  });

  final List<String> subjects;
  final List<AbsenceRecord> records;
}

class AttendanceStorage {
  AttendanceStorage._();

  static const MethodChannel _channel = MethodChannel('campus_flow.widget_sync');

  static Future<AttendanceData> loadAttendanceData() async {
    try {
      final encoded = await _channel.invokeMethod<String>('loadAttendance');
      if (encoded == null || encoded.isEmpty) {
        return const AttendanceData(subjects: [], records: []);
      }
      final decoded = jsonDecode(encoded) as Map<String, dynamic>;
      final subjects = (decoded['subjects'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final recordsRaw = (decoded['records'] as List<dynamic>?) ?? [];
      final records = recordsRaw.map((item) => AbsenceRecord.fromJson(item as Map<String, dynamic>)).toList();
      return AttendanceData(subjects: subjects, records: records);
    } catch (_) {
      return const AttendanceData(subjects: [], records: []);
    }
  }

  static Future<void> saveAttendanceData(AttendanceData data) async {
    try {
      final payload = jsonEncode({
        'subjects': data.subjects,
        'records': data.records.map((r) => r.toJson()).toList(),
      });
      await _channel.invokeMethod<void>(
        'saveAttendance',
        {'attendance': payload},
      );
    } catch (_) {
      return;
    }
  }
}
