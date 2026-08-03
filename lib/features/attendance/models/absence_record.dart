import 'dart:convert';

class AbsenceRecord {
  const AbsenceRecord({
    required this.id,
    required this.subjectName,
    required this.date,
    required this.reason,
    required this.isValid,
    this.hours = 1.0,
  });

  final String id;
  final String subjectName;
  final DateTime date;
  final String reason;
  final bool isValid;
  final double hours;

  factory AbsenceRecord.fromJson(Map<String, dynamic> json) {
    return AbsenceRecord(
      id: json['id'] as String,
      subjectName: json['subjectName'] as String,
      date: DateTime.parse(json['date'] as String),
      reason: json['reason'] as String? ?? 'No reason provided',
      isValid: json['isValid'] as bool? ?? false,
      hours: (json['hours'] as num?)?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectName': subjectName,
      'date': date.toIso8601String(),
      'reason': reason,
      'isValid': isValid,
      'hours': hours,
    };
  }

  AbsenceRecord copyWith({
    String? id,
    String? subjectName,
    DateTime? date,
    String? reason,
    bool? isValid,
    double? hours,
  }) {
    return AbsenceRecord(
      id: id ?? this.id,
      subjectName: subjectName ?? this.subjectName,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      isValid: isValid ?? this.isValid,
      hours: hours ?? this.hours,
    );
  }
}

String formatHours(double hours) {
  if (hours % 1 == 0) {
    final intVal = hours.toInt();
    return '$intVal ${intVal == 1 ? 'Hour' : 'Hours'}';
  }
  return '$hours Hours';
}

String formatHoursShort(double hours) {
  if (hours % 1 == 0) {
    final intVal = hours.toInt();
    return '$intVal ${intVal == 1 ? 'hr' : 'hrs'}';
  }
  return '$hours hrs';
}

String encodeAbsenceRecords(List<AbsenceRecord> records) {
  return jsonEncode(records.map((r) => r.toJson()).toList());
}

List<AbsenceRecord> decodeAbsenceRecords(String? encoded) {
  if (encoded == null || encoded.isEmpty) {
    return [];
  }
  final decoded = jsonDecode(encoded) as List<dynamic>;
  return decoded.map((item) => AbsenceRecord.fromJson(item as Map<String, dynamic>)).toList();
}
