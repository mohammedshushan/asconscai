import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/loan_type_model.dart';
import '../models/loan_request_model.dart';
import 'logging_service.dart';

class LoanService {
  final String _baseUrl = 'http://49.12.83.111:7003/ords/ascon_scai/hrapi/';
  final _headers = {'Content-Type': 'application/json'};
  final http.Client _client;

  LoanService({http.Client? client})
    : _client = LoggingClient(client ?? http.Client());

  // ملاحظة: تم استخدام نفس API الصلاحيات بناءً على طلبك
  Future<bool> checkLoanAccess(String userCode) async {
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

  Future<List<LoanType>> getLoanTypes() async {
    final url = Uri.parse('${_baseUrl}loan_types');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final items = json.decode(response.body)['items'] as List;
        return items.map((item) => LoanType.fromJson(item)).toList();
      }
      throw Exception(
        'Failed to load loan types. Code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Exception getting loan types: $e');
    }
  }

  Future<List<LoanRequest>> getLoanRequests(String empCode) async {
    final url = Uri.parse('${_baseUrl}loan_request/$empCode');
    try {
      final response = await _client.get(url, headers: _headers);
      if (response.statusCode == 200) {
        final items = json.decode(response.body)['items'] as List;
        return items.map((item) => LoanRequest.fromJson(item)).toList();
      }
      throw Exception(
        'Failed to load loan requests. Code: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Exception getting loan requests: $e');
    }
  }

  Future<bool> addLoanRequest(Map<String, dynamic> loanData) async {
    final url = Uri.parse('${_baseUrl}add_loan_request');
    try {
      // تحويل التواريخ إلى صيغة YYYY-MM-DD كما هو مطلوب
      final dateFormat = DateFormat('yyyy-MM-dd');
      loanData['req_loan_date'] = dateFormat.format(DateTime.now());
      loanData['loan_start_ddct_dt'] = dateFormat.format(DateTime.now());
      loanData['loan_start_date'] = dateFormat.format(
        DateTime.parse(loanData['loan_start_date']),
      );

      // تحويل كل القيم إلى String لضمان التوافق
      final body = json.encode(
        loanData.map((key, value) => MapEntry(key, value.toString())),
      );

      final response = await _client.post(url, headers: _headers, body: body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
