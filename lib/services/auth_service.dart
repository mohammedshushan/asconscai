/*
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import '../utils/device_info_provider.dart';
import 'package:geolocator/geolocator.dart'; // <-- استيراد Position

class AuthService {
  final ApiService _apiService = ApiService();
  final DeviceInfoProvider _deviceInfoProvider = DeviceInfoProvider();
  static const String _userKey = 'loggedInUser';

  Future<UserModel> login(String userCode, String password) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception('noInternet');
    }

    final List<UserModel> allUsers = await _apiService.getAllUsers();

    UserModel? user;
    try {
      user = allUsers.firstWhere(
            (u) => u.usersCode.toString() == userCode,
      );
    } catch (e) {
      throw Exception('userNotFound');
    }

    if (user.password != password) {
      throw Exception('invalidPassword');
    }

    await _saveUser(user);

    // لا ننتظر هذه الدالة، ستعمل في الخلفية
    _postActivity(user.usersCode);

    return user;
  }

  Future<void> _postActivity(int userCode) async {
    try {
      // جلب كل البيانات المطلوبة
      final ip = await _deviceInfoProvider.getIpAddress();
      final deviceId = await _deviceInfoProvider.getDeviceUniqueId();
      final osUser = await _deviceInfoProvider.getOsUser();
      //final String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc());
      final String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc().add(Duration(hours: 1)));
      // **الخطوة الجديدة: جلب الموقع**
      Position? position;
      try {
        position = await _deviceInfoProvider.determinePosition();
      } catch (e) {
        print("Could not get location: $e");
        // سنكمل بدون موقع إذا فشل جلبه
      }

      final Map<String, dynamic> loginData = {
        "users_code": userCode,
        "machine_ip": ip,
        "machine_mac": deviceId,
        "osuser": osUser,
        "contime": formattedDate,
        // **إضافة الإحداثيات إلى البيانات**
        // إذا كان الموقع غير متاح، سيتم إرسال null
        "latitude": position?.latitude,
        "longitude": position?.longitude,
      };

      print('data loginData $loginData');
      await _apiService.postLoginData(loginData);

    } catch (e) {
      print("Could not post activity data: $e");
    }
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<UserModel?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(_userKey);
    if (userData != null) {
      return UserModel.fromJson(json.decode(userData));
    }
    return null;
  }
}
*/
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import '../utils/device_info_provider.dart';
import 'package:geolocator/geolocator.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final DeviceInfoProvider _deviceInfoProvider = DeviceInfoProvider();
  static const String _userKey = 'loggedInUser';

  Future<UserModel> login(String userCode, String password) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw Exception('no_internet');
    }

    try {
      final List<UserModel> allUsers = await _apiService.getAllUsers();

      UserModel? user;
      try {
        user = allUsers.firstWhere(
              (u) => u.usersCode.toString() == userCode,
        );
      } catch (e) {
        // إذا لم يتم العثور على المستخدم أو كانت كلمة المرور خطأ، نرسل نفس الخطأ
        // هذا أفضل من الناحية الأمنية لأنه لا يخبر المهاجم أي جزء من البيانات كان خاطئًا
        throw Exception('invalid_credentials');
      }

      if (user.password != password) {
        throw Exception('invalid_credentials');
      }

      await _saveUser(user);

      // لا ننتظر هذه الدالة، ستعمل في الخلفية
      _postActivity(user.usersCode);

      return user;
    } catch (e) {
      // إذا كان الخطأ هو خطأ بيانات الدخول، قم بتمريره كما هو
      if (e.toString().contains('invalid_credentials')) {
        rethrow;
      }
      // أي خطأ آخر يعتبر خطأ تقنيًا (مشكلة في السيرفر أو الشبكة)
      print("A technical error occurred during login: $e");
      throw Exception('network_error');
    }
  }

  Future<void> _postActivity(int userCode) async {
    try {
      final ip = await _deviceInfoProvider.getIpAddress();
      final deviceId = await _deviceInfoProvider.getDeviceUniqueId();
      final osUser = await _deviceInfoProvider.getOsUser();
      final String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'").format(DateTime.now().toUtc().add(Duration(hours: 1)));

      Position? position;
      try {
        position = await _deviceInfoProvider.determinePosition();
      } catch (e) {
        print("Could not get location for activity post: $e");
      }

      final Map<String, dynamic> loginData = {
        "users_code": userCode,
        "machine_ip": ip,
        "machine_mac": deviceId,
        "osuser": osUser,
        "contime": formattedDate,
        "latitude": position?.latitude,
        "longitude": position?.longitude,
      };

      print('data loginData $loginData');
      await _apiService.postLoginData(loginData);

    } catch (e) {
      print("Could not post activity data: $e");
    }
  }

  Future<void> _saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  Future<UserModel?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString(_userKey);
    if (userData != null) {
      return UserModel.fromJson(json.decode(userData));
    }
    return null;
  }
}