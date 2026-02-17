import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/vacation_balance_model.dart';
import '../models/vacation_type_model.dart';
import '../models/vacation_order_model.dart';
import 'logging_service.dart';

class VacationService {
  final String _baseUrl = 'http://49.12.83.111:7003/ords/ascon_scai/hrapi/';
  final _headers = {'Content-Type': 'application/json'};
  final http.Client _client;

  VacationService({http.Client? client})
    : _client = LoggingClient(client ?? http.Client());

  Future<bool> checkVacationAccess(String userCode) async {
    final url = Uri.parse('${_baseUrl}emp_access_vcnc_loan/$userCode');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        return (json.decode(response.body)['items'] as List).isNotEmpty;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<List<VacationBalance>> getVacationBalance(String empCode) async {
    final url = Uri.parse('${_baseUrl}vcnc_balance/$empCode');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final items = json.decode(response.body)['items'] as List;
        return items.map((item) => VacationBalance.fromJson(item)).toList();
      }
      throw Exception('Failed to load balance. Code: ${response.statusCode}');
    } catch (e) {
      throw Exception('Exception getting balance: $e');
    }
  }

  // دالة جديدة لجلب أنواع الإجازات
  Future<List<VacationType>> getVacationTypes() async {
    final url = Uri.parse('${_baseUrl}vcnc_types');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final items = json.decode(response.body)['items'] as List;
        return items.map((item) => VacationType.fromJson(item)).toList();
      }
      throw Exception(
        'Failed to load vacation types. Code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Exception getting vacation types: $e');
    }
  }

  // دالة جديدة لجلب طلبات الإجازة السابقة
  Future<List<VacationOrder>> getVacationOrders(String empCode) async {
    final url = Uri.parse('${_baseUrl}vcnc_order/$empCode');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final items = json.decode(response.body)['items'] as List;
        return items.map((item) => VacationOrder.fromJson(item)).toList();
      }
      throw Exception(
        'Failed to load vacation orders. Code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Exception getting vacation orders: $e');
    }
  }

  // دالة جديدة لإضافة طلب إجازة
  Future<bool> addVacationOrder(Map<String, dynamic> orderData) async {
    final url = Uri.parse('${_baseUrl}add_vcnc_orders');
    try {
      // تحويل التواريخ إلى صيغة YYYY-MM-DD فقط
      DateTime startDate = DateTime.parse(orderData['start_dt']);
      DateTime endDate = DateTime.parse(orderData['end_dt']);
      DateTime returnDate = DateTime.parse(orderData['return_date']);
      DateTime now = DateTime.now();

      // تحديث البيانات بالصيغة المطلوبة
      orderData['trns_date'] =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      orderData['start_dt'] =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
      orderData['end_dt'] =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";
      orderData['return_date'] =
          "${returnDate.year}-${returnDate.month.toString().padLeft(2, '0')}-${returnDate.day.toString().padLeft(2, '0')}";

      // تحويل القيم إلى String إذا لم تكن كذلك
      orderData['serial_pyv'] = orderData['serial_pyv'].toString();
      orderData['period'] = orderData['period'].toString();
      orderData['agree_flag'] = orderData['agree_flag'].toString();

      final response = await _client.post(
        url,
        headers: _headers,
        body: json.encode(orderData),
      );

      return false;
    } catch (e) {
      return false;
    }
  }
}
