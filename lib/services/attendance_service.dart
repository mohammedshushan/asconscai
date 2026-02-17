import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/attendance_model.dart';
import 'logging_service.dart';

class AttendanceService {
  final String _baseUrl = 'http://49.12.83.111:7003/ords/ascon_scai/hrapi';
  final http.Client _client;

  AttendanceService({http.Client? client})
    : _client = LoggingClient(client ?? http.Client());

  // --- دوال جلب البيانات تبقى كما هي بدون تغيير ---
  Future<List<AttendanceMonthSummary>> getAttendanceMonths(int empCode) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/get_attendnace_count_month/$empCode'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      return items
          .map((item) => AttendanceMonthSummary.fromJson(item))
          .toList();
    } else {
      throw Exception('Failed to load attendance months');
    }
  }

  Future<List<AttendanceRecord>> getAttendanceDetails(
    int empCode,
    String yearMonth,
  ) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/get_attendnace_filter_month/$empCode/$yearMonth'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => AttendanceRecord.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load attendance details');
    }
  }

  // --- ✅ تعديل دالة إرسال البصمة لاستخدام http ---
  Future<void> postAttendanceRecord(
    int empCode,
    Map<String, dynamic> data,
  ) async {
    final url = '$_baseUrl/ta_attendance/$empCode';

    try {
      final response = await _client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(data), // تحويل البيانات إلى نص JSON
      );

      // الـ API الخاص بـ Oracle ADF غالباً ما يرجع 201 للإنشاء الناجح أو 200
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          'Failed to post attendance record. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } catch (e) {
      // إعادة رمي الخطأ للتعامل معه في واجهة المستخدم
      throw Exception('Error connecting to the server: $e');
    }
  }
}
