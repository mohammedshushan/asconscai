// مسار الملف: lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../models/module_model.dart';

class ApiService {
  final String _baseUrl = "http://49.12.83.111:7001/ords/ascon_scai";

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
