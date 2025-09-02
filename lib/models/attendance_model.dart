// lib/models/attendance_model.dart

// نموذج لبيانات ملخص الشهور
class AttendanceMonthSummary {
  final String yearMonth;
  final int workYear;
  final int workMonth;
  final int recordCount;


  AttendanceMonthSummary({
    required this.yearMonth,
    required this.workYear,
    required this.workMonth,
    required this.recordCount,

  });

  factory AttendanceMonthSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceMonthSummary(
      yearMonth: json['year_month'],
      workYear: json['work_year'],
      workMonth: json['work_month'],
      recordCount: json['record_count'],

    );
  }
}

// نموذج لبيانات سجل الحضور التفصيلي
class AttendanceRecord {
  final DateTime workDay;
  final DateTime recordTime;
  final int state; // 0: دخول, 1: خروج
  final double latitude; // <-- الإضافة الأولى
  final double longitude; // <-- الإضافة الثانية
  final int ser;

  AttendanceRecord({
    required this.workDay,
    required this.recordTime,
    required this.state,
    required this.latitude,
    required this.longitude,
    required this.ser
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      workDay: DateTime.parse(json['work_day']),
      recordTime: DateTime.parse(json['record_time']),
      state: json['state'],
      // التأكد من أن القيمة من نوع double
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      ser: json['ser'],
    );
  }
}