import 'dart:convert';
import 'package:http/http.dart' as http;
import 'logging_service.dart';

class ProfileService {
  static const String _baseUrl =
      'http://49.12.83.111:7003/ords/ascon_scai/hrapi';
  static const Duration _timeout = Duration(seconds: 30);
  final http.Client _client;

  ProfileService({http.Client? client})
    : _client = LoggingClient(client ?? http.Client());

  // الحصول على بيانات الملف الشخصي
  Future<Map<String, dynamic>?> getProfileData(int userCode) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/emp_info/$userCode'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['items'] != null && data['items'].isNotEmpty) {
          return data['items'][0];
        } else {
          throw Exception('No profile data found');
        }
      } else {
        throw Exception('Failed to load profile data: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // رفع صورة جديدة للملف الشخصي
  Future<bool> uploadProfileImage(int userCode, String base64Image) async {
    try {
      final requestData = {'emp_id': userCode, 'photo': base64Image};

      final response = await _client
          .post(
            Uri.parse('$_baseUrl/emp_photo'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestData),
          )
          .timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // الحصول على URL صورة الملف الشخصي
  String getProfileImageUrl(int userCode, {bool forceRefresh = false}) {
    String url = '$_baseUrl/emp_photo/$userCode';
    if (forceRefresh) {
      url += '?t=${DateTime.now().millisecondsSinceEpoch}';
    }
    return url;
  }

  // فحص الاتصال بالإنترنت والخدمة
  Future<bool> checkServiceConnection(int userCode) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$_baseUrl/emp_info/$userCode'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
