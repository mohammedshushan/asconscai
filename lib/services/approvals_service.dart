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
import 'package:flutter/foundation.dart'; // Required for debugPrint
import 'package:http/http.dart' as http;
import '../models/pending_loan_model.dart';
import '../models/pending_permission_model.dart';
import '../models/pending_vacation_model.dart';

class ApprovalsService {
  final String _baseUrl = 'http://49.12.83.111:7001/ords/ascon_scai/hrapi';

  // Helper for pretty printing JSON
  static void _prettyPrintJson(String input) {
    try {
      const JsonDecoder decoder = JsonDecoder();
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final dynamic object = decoder.convert(input);
      final dynamic prettyString = encoder.convert(object);
      prettyString.split('\n').forEach((dynamic element) => debugPrint(element));
    } catch (e) {
      debugPrint(input); // If it's not a valid JSON, print as is
    }
  }

  // ==================== Vacation Approvals ====================
  Future<List<PendingVacationRequest>> getPendingVacationRequests(String userCode) async {
    final url = Uri.parse('$_baseUrl/get_vcnc_auth_user/$userCode');
    print('🔄 [API Call] getPendingVacationRequests for user: $userCode');
    print('  - URL: $url');
    try {
      final response = await http.get(url);
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('  - ✅ Success');
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => PendingVacationRequest.fromJson(item)).toList();
      } else {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to load pending vacation requests');
      }
    } catch (e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  Future<void> updateVacationStatus(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/update_status_vcnc');
    print('🔄 [API Call] updateVacationStatus');
    print('  - URL: $url');
    print('  - 📤 Payload:');
    _prettyPrintJson(json.encode(data));
    try {
      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to update vacation status');
      }
      print('  - ✅ Success');
    } catch(e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  Future<void> addVacationToOrders(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/add_vcnc_orders');
    print('🔄 [API Call] addVacationToOrders');
    print('  - URL: $url');
    print('  - 📤 Payload:');
    _prettyPrintJson(json.encode(data));
    try {
      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to add vacation to orders');
      }
      print('  - ✅ Success');
    } catch(e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  // ==================== Permission Approvals ====================
  Future<int> getPendingPermissionsCount(String userCode) async {
    final url = Uri.parse('$_baseUrl/get_exist_auth_user/$userCode');
    print('🔄 [API Call] getPendingPermissionsCount for user: $userCode');
    print('  - URL: $url');
    try {
      final response = await http.get(url);
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('  - ✅ Success');
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to load pending permissions count');
      }
    } catch (e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  Future<List<PendingPermissionRequest>> getPendingPermissionRequests(String userCode) async {
    final url = Uri.parse('$_baseUrl/get_exist_auth_user/$userCode');
    print('🔄 [API Call] getPendingPermissionRequests for user: $userCode');
    print('  - URL: $url');
    try {
      final response = await http.get(url);
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('  - ✅ Success');
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => PendingPermissionRequest.fromJson(item)).toList();
      } else {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to load pending permission requests');
      }
    } catch (e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  Future<void> updatePermissionStatus(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/update_status_exist');
    print('🔄 [API Call] updatePermissionStatus');
    print('  - URL: $url');
    print('  - 📤 Payload:');
    _prettyPrintJson(json.encode(data));
    try {
      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to update permission status');
      }
      print('  - ✅ Success');
    } catch(e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  Future<void> updatePermissionInOrders(Map<String, dynamic> data) async {
    final empCode = data['emp_code'];
    final url = Uri.parse('$_baseUrl/get_post_exist_request/$empCode');
    print('🔄 [API Call] updatePermissionInOrders');
    print('  - URL: $url');
    print('  - 📤 Payload:');
    _prettyPrintJson(json.encode(data));
    try {
      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to update permission in orders');
      }
      print('  - ✅ Success');
    } catch (e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  // ==================== Loan Approvals ====================
  Future<int> getPendingLoansCount(String userCode) async {
    final url = Uri.parse('$_baseUrl/get_loan_auth_user/$userCode');
    print('🔄 [API Call] getPendingLoansCount for user: $userCode');
    print('  - URL: $url');
    try {
      final response = await http.get(url);
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('  - ✅ Success');
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to load pending loans count');
      }
    } catch (e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  Future<List<PendingLoanRequest>> getPendingLoanRequests(String userCode) async {
    final url = Uri.parse('$_baseUrl/get_loan_auth_user/$userCode');
    print('🔄 [API Call] getPendingLoanRequests for user: $userCode');
    print('  - URL: $url');
    try {
      final response = await http.get(url);
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('  - ✅ Success');
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => PendingLoanRequest.fromJson(item)).toList();
      } else {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to load pending loan requests');
      }
    } catch(e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  Future<void> updateLoanStatus(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/update_loan_status');
    print('🔄 [API Call] updateLoanStatus');
    print('  - URL: $url');
    print('  - 📤 Payload:');
    _prettyPrintJson(json.encode(data));
    try {
      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to update loan status. Body: ${response.body}');
      }
      print('  - ✅ Success');
    } catch(e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }

  Future<void> updateLoanInOrders(Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/add_loan_request');
    print('🔄 [API Call] updateLoanInOrders');
    print('  - URL: $url');
    print('  - 📤 Payload:');
    _prettyPrintJson(json.encode(data));
    try {
      final response = await http.put(url, headers: {'Content-Type': 'application/json'}, body: json.encode(data));
      print('  - Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('  - ❌ Failure');
        debugPrint('  - Response Body:');
        _prettyPrintJson(response.body);
        throw Exception('Failed to update loan in orders. Body: ${response.body}');
      }
      print('  - ✅ Success');
    } catch(e) {
      print('  - ❌ Exception: $e');
      rethrow;
    }
  }
}