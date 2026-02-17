/*
import 'dart:convert';
import 'package:asconscai/models/pending_loan_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pending_permission_model.dart'; // ### إضافة جديدة
import '../models/pending_vacation_model.dart';

class ApprovalsService {
  final String _baseUrl = 'http://49.12.83.111:7001/ords/ascon_scai/hrapi';

  // ==================== Vacation Approvals ====================
  Future<List<PendingVacationRequest>> getPendingVacationRequests(String userCode) async {
    final response = await http.get(Uri.parse('$_baseUrl/get_vcnc_auth_user/$userCode'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => PendingVacationRequest.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load pending vacation requests');
    }
  }

  Future<void> updateVacationStatus(Map<String, dynamic> data) async {
    final url = '$_baseUrl/update_status_vcnc';
    final response = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to update vacation status');
    }
  }

  Future<void> addVacationToOrders(Map<String, dynamic> data) async {
    final url = '$_baseUrl/add_vcnc_orders';
    final response = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to add vacation to orders');
    }
  }

  // ==================== Permission Approvals (### إضافة جديدة) ====================

  // جلب عدد الأذونات المعلقة للوحة التحكم
  Future<int> getPendingPermissionsCount(String userCode) async {
    final response = await http.get(Uri.parse('$_baseUrl/get_exist_auth_user/$userCode'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Failed to load pending permissions count');
    }
  }

  // جلب قائمة الأذونات المعلقة
  Future<List<PendingPermissionRequest>> getPendingPermissionRequests(String userCode) async {
    final response = await http.get(Uri.parse('$_baseUrl/get_exist_auth_user/$userCode'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => PendingPermissionRequest.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load pending permission requests');
    }
  }

  // تحديث حالة الإذن (المرحلة الأولى)
  Future<void> updatePermissionStatus(Map<String, dynamic> data) async {
    final url = '$_baseUrl/update_status_exist';
    debugPrint("==== 📤 Updating Permission Status ====\nURL: $url\nPayload: ${json.encode(data)}");
    final response = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    debugPrint("==== ✅ Update Permission Response ====\nStatus Code: ${response.statusCode}\nResponse Body: ${response.body}");
    if (response.statusCode != 200) {
      throw Exception('Failed to update permission status');
    }
  }

  // تحديث الإذن في السجلات النهائية (المرحلة الثانية)
  Future<void> updatePermissionInOrders(Map<String, dynamic> data) async {
    final empCode = data['emp_code']; // استخراج كود الموظف للينك
    final url = '$_baseUrl/get_post_exist_request/$empCode';
    debugPrint("==== 📤 Updating Permission in Orders ====\nURL: $url\nPayload: ${json.encode(data)}");
    final response = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    debugPrint("==== ✅ Update in Orders Response ====\nStatus Code: ${response.statusCode}\nResponse Body: ${response.body}");
    if (response.statusCode != 200) {
      throw Exception('Failed to update permission in orders');
    }
  }


  // ==================== Loan Approvals (### إضافة جديدة) ====================

  Future<int> getPendingLoansCount(String userCode) async {
    final response = await http.get(Uri.parse('$_baseUrl/get_loan_auth_user/$userCode'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['count'] ?? 0;
    } else {
      throw Exception('Failed to load pending loans count');
    }
  }

  Future<List<PendingLoanRequest>> getPendingLoanRequests(String userCode) async {
    final response = await http.get(Uri.parse('$_baseUrl/get_loan_auth_user/$userCode'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => PendingLoanRequest.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load pending loan requests');
    }
  }

  Future<void> updateLoanStatus(Map<String, dynamic> data) async {
    final url = '$_baseUrl/update_loan_status';
    final response = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to update loan status. Body: ${response.body}');
    }
  }

  Future<void> updateLoanInOrders(Map<String, dynamic> data) async {
    final url = '$_baseUrl/add_loan_request';
    final response = await http.put(Uri.parse(url), headers: {'Content-Type': 'application/json'}, body: json.encode(data));
    if (response.statusCode != 200) {
      throw Exception('Failed to update loan in orders. Body: ${response.body}');
    }
  }

}
*/
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pending_loan_model.dart';
import '../models/pending_permission_model.dart';
import '../models/pending_vacation_model.dart';
import 'logging_service.dart';

class ApprovalsService {
  final String _baseUrl = 'http://49.12.83.111:7003/ords/ascon_scai/hrapi';
  final http.Client _client;

  ApprovalsService({http.Client? client})
    : _client = LoggingClient(client ?? http.Client());

  // ==================== Vacation Approvals ====================
  Future<List<PendingVacationRequest>> getPendingVacationRequests(
    String userCode,
  ) async {
    final url = Uri.parse('$_baseUrl/get_vcnc_auth_user/$userCode');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items
            .map((item) => PendingVacationRequest.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load pending vacation requests');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateVacationStatus(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/update_status_vcnc');
    try {
      final response = await _client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update vacation status');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addVacationToOrders(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/add_vcnc_orders');
    try {
      final response = await _client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to add vacation to orders');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Permission Approvals ====================
  Future<int> getPendingPermissionsCount(String userCode) async {
    final url = Uri.parse('$_baseUrl/get_exist_auth_user/$userCode');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to load pending permissions count');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PendingPermissionRequest>> getPendingPermissionRequests(
    String userCode,
  ) async {
    final url = Uri.parse('$_baseUrl/get_exist_auth_user/$userCode');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items
            .map((item) => PendingPermissionRequest.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to load pending permission requests');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePermissionStatus(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/update_status_exist');
    try {
      final response = await _client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update permission status');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updatePermissionInOrders(Map<String, dynamic> data) async {
    final empCode = data['emp_code'];
    final url = Uri.parse('$_baseUrl/get_post_exist_request/$empCode');
    try {
      final response = await _client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update permission in orders');
      }
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Loan Approvals ====================
  Future<int> getPendingLoansCount(String userCode) async {
    final url = Uri.parse('$_baseUrl/get_loan_auth_user/$userCode');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to load pending loans count');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PendingLoanRequest>> getPendingLoanRequests(
    String userCode,
  ) async {
    final url = Uri.parse('$_baseUrl/get_loan_auth_user/$userCode');
    try {
      final response = await _client.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => PendingLoanRequest.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load pending loan requests');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLoanStatus(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/update_loan_status');
    try {
      final response = await _client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update loan status. Body: ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLoanInOrders(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/add_loan_request');
    try {
      final response = await _client.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to update loan in orders. Body: ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}
