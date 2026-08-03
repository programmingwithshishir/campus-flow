import 'dart:convert';

class CourseAttendance {
  const CourseAttendance({
    required this.id,
    required this.courseName,
    this.missedClasses = 0,
  });

  final String id;
  final String courseName;
  final int missedClasses;

  factory CourseAttendance.fromJson(Map<String, dynamic> json) {
    return CourseAttendance(
      id: json['id'] as String,
      courseName: json['courseName'] as String,
      missedClasses: (json['missedClasses'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseName': courseName,
      'missedClasses': missedClasses,
    };
  }

  CourseAttendance copyWith({
    String? id,
    String? courseName,
    int? missedClasses,
  }) {
    return CourseAttendance(
      id: id ?? this.id,
      courseName: courseName ?? this.courseName,
      missedClasses: missedClasses ?? this.missedClasses,
    );
  }
}

String encodeAttendance(List<CourseAttendance> courses) {
  return jsonEncode(courses.map((course) => course.toJson()).toList());
}

List<CourseAttendance> decodeAttendance(String? encoded) {
  if (encoded == null || encoded.isEmpty) {
    return [];
  }
  final decoded = jsonDecode(encoded) as List<dynamic>;
  return decoded.map((item) => CourseAttendance.fromJson(item as Map<String, dynamic>)).toList();
}
