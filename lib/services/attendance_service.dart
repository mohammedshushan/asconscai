import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // <-- استبدال dio بـ http
import '../models/attendance_model.dart';

class AttendanceService {
  final String _baseUrl = 'http://49.12.83.111:7003/ords/ascon_scai/hrapi';

  // --- دوال جلب البيانات تبقى كما هي بدون تغيير ---
  Future<List<AttendanceMonthSummary>> getAttendanceMonths(int empCode) async {
    // ... هذا الكود لا يتغير
    final response = await http.get(Uri.parse('$_baseUrl/get_attendnace_count_month/$empCode'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => AttendanceMonthSummary.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load attendance months');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceDetails(int empCode, String yearMonth) async {
    // ... هذا الكود لا يتغير
    final response = await http.get(Uri.parse('$_baseUrl/get_attendnace_filter_month/$empCode/$yearMonth'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => AttendanceRecord.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load attendance details');
    }
  }


  // --- ✅ تعديل دالة إرسال البصمة لاستخدام http ---
  Future<void> postAttendanceRecord(int empCode, Map<String, dynamic> data) async {
    final url = '$_baseUrl/ta_attendance/$empCode';

    debugPrint("==== 📤 Sending Attendance Data (using http) ====");
    debugPrint("URL: $url");
    debugPrint("Payload: ${json.encode(data)}");

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: json.encode(data), // تحويل البيانات إلى نص JSON
      );

      debugPrint("==== ✅ Attendance API Response ====");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      // الـ API الخاص بـ Oracle ADF غالباً ما يرجع 201 للإنشاء الناجح أو 200
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception('Failed to post attendance record. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      debugPrint("==== ❌ Attendance API Error ====");
      debugPrint(e.toString());
      // إعادة رمي الخطأ للتعامل معه في واجهة المستخدم
      throw Exception('Error connecting to the server: $e');
    }
  }
}