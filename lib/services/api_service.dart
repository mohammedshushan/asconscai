// مسار الملف: lib/services/api_service.dart
/*
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/module_model.dart';

class ApiService {
  final String _baseUrl = "http://49.12.83.111:7003/ords/ascon_scai";

  Future<List<UserModel>> getAllUsers() async {
    final response = await http.get(Uri.parse('$_baseUrl/hrapi/all_emp'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      return items.map((item) => UserModel.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<List<ModuleModel>> getModules() async {
    final response = await http.get(Uri.parse('$_baseUrl/sysmodule/allmodule'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      List<ModuleModel> modules = items.map((item) => ModuleModel.fromJson(item)).toList();
      modules.sort((a, b) => a.order.compareTo(b.order));
      return modules;
    } else {
      throw Exception('Failed to load modules');
    }
  }

  Future<void> postLoginData(Map<String, dynamic> loginData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/hrapi/ACCESSINFO'), // <-- تأكد من صحة هذا الرابط
        headers: {'Content-Type': 'application/json'},
        body: json.encode(loginData),
      );
      print('data loginData $loginData');
      // الخادم يرد بـ 201 عند الإنشاء الناجح عادةً
      if (response.statusCode != 200 && response.statusCode != 201) {
        print('Failed to post login data. Status: ${response.statusCode}');
        // طباعة الخطأ الذي أرسلته لي
        print('Response Body: ${response.body}');
      } else {
        print('Response Body: ${response.body}');
        print('Login activity posted successfully!');
      }
    } catch (e) {
      print('Error posting login data: $e');
    }
  }
}
*/

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/module_model.dart';
import 'logging_service.dart';

class ApiService {
  final String _baseUrl = "http://49.12.83.111:7003/ords/ascon_scai";
  final http.Client _client;

  ApiService({http.Client? client})
    : _client = LoggingClient(client ?? http.Client());

  // إضافة timeout
  static const Duration timeoutDuration = Duration(seconds: 30);

  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/hrapi/all_emp'))
          .timeout(
            timeoutDuration,
            onTimeout: () {
              throw TimeoutException('فشل الاتصال - انتظر مدة طويلة');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'];
        return items.map((item) => UserModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'فشل تحميل المستخدمين - الحالة: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ModuleModel>> getModules() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/sysmodule/allmodule'))
          .timeout(
            timeoutDuration,
            onTimeout: () {
              throw TimeoutException('انتهت مهلة الاتصال بالـ API');
            },
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // تحقق من وجود 'items'
        if (data['items'] == null || data['items'].isEmpty) {
          return [];
        }

        final List<dynamic> items = data['items'];

        List<ModuleModel> modules =
            items.map((item) {
              try {
                return ModuleModel.fromJson(item);
              } catch (e) {
                rethrow;
              }
            }).toList();

        modules.sort((a, b) => a.order.compareTo(b.order));
        return modules;
      } else {
        throw Exception(
          'فشل تحميل الوحدات\n'
          'الحالة: ${response.statusCode}\n'
          'الرسالة: ${response.body}',
        );
      }
    } on TimeoutException catch (e) {
      throw Exception('انقطع الاتصال - حاول مرة أخرى');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> postLoginData(Map<String, dynamic> loginData) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$_baseUrl/hrapi/ACCESSINFO'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(loginData),
          )
          .timeout(
            timeoutDuration,
            onTimeout: () {
              throw TimeoutException('انتهت مهلة تسجيل الدخول');
            },
          );

      if (response.statusCode != 200 && response.statusCode != 201) {
        // Logging is handled by LoggingClient
      } else {
        // Logging is handled by LoggingClient
      }
    } on TimeoutException catch (e) {
      // Re-throw or handle as needed
    } catch (_) {
      // Re-throw or handle as needed
    }
  }
}
