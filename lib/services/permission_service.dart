import 'dart:async';
import 'dart:convert';
import 'dart:io'; // <-- إضافة مهمة للتعامل مع SocketException
import 'package:asconscai/models/permissions/permission_request_model.dart';
import 'package:asconscai/models/permissions/permission_type_model.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';



class PermissionService {
  final String _baseUrl = "http://49.12.83.111:7001/ords/ascon_scai/hrapi";

  // دالة موحدة للتعامل مع أخطاء الشبكة
  Future<T> _handleApiCall<T>(Future<T> Function() apiCall) async {
    try {
      return await apiCall();
    } on SocketException {
      throw Exception('No Internet Connection');
    } on TimeoutException {
      throw Exception('The connection has timed out, Please try again!');
    } catch (e) {
      // يمكنك التعامل مع أخطاء أخرى هنا إذا أردت
      rethrow;
    }
  }

  Future<List<PermissionType>> getPermissionTypes() async {
    return _handleApiCall(() async {
      final response = await http.get(Uri.parse('$_baseUrl/get_exits_type'));
      if (response.statusCode == 200) {
        return parsePermissionTypes(response.body);
      } else {
        throw Exception('Failed to load permission types');
      }
    });
  }

  Future<List<PermissionRequest>> getPermissionRequests(String empCode) async {
    return _handleApiCall(() async {
      final response = await http.get(Uri.parse('$_baseUrl/get_post_exist_request/$empCode'));
      if (response.statusCode == 200) {
        return parsePermissionRequests(response.body);
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to load permission requests. Status code: ${response.statusCode}');
      }
    });
  }

  Future<int> getMaxSerial() async {
    return _handleApiCall(() async {
      final response = await http.get(Uri.parse('$_baseUrl/get_all_exist_request'));
      if (response.statusCode == 200) {
        final requests = parsePermissionRequests(response.body);
        return requests.map((r) => r.serial).maxOrNull ?? 0;
      } else {
        throw Exception('Failed to load all requests for serial');
      }
    });
  }

  Future<bool> addPermissionRequest(Map<String, dynamic> requestData) async {
    return _handleApiCall(() async {
      final empCode = requestData['emp_code'];
      final response = await http.post(
        Uri.parse('$_baseUrl/get_post_exist_request/$empCode'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    });
  }
}