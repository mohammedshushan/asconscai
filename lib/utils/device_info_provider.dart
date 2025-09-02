/*
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // <-- استيراد الحزمة الجديدة

class DeviceInfoProvider {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final NetworkInfo _networkInfo = NetworkInfo();
  final Uuid _uuid = const Uuid(); // <-- إنشاء كائن لتوليد المعرف

  Future<String?> getIpAddress() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      print('Could not get IP Address: $e');
      return 'Unknown IP';
    }
  }

  Future<String?> getOsUser() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.name;
      }
    } catch (e) {
      print('Could not get OS User: $e');
    }
    return 'Unknown Device';
  }

  // **الدالة الجديدة والمهمة**
  // ستحل هذه الدالة محل getMacAddress
  Future<String> getDeviceUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'device_unique_id';

    // التحقق من وجود معرف محفوظ مسبقاً
    String? existingId = prefs.getString(key);

    if (existingId != null) {
      // إذا كان موجوداً، قم بإعادته
      return existingId;
    } else {
      // إذا لم يكن موجوداً، قم بتوليد معرف جديد
      String newId = _uuid.v4();
      // حفظ المعرف الجديد لاستخدامه في المرات القادمة
      await prefs.setString(key, newId);
      return newId;
    }
  }
}*/



// مسار الملف: lib/utils/device_info_provider.dart
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart'; // <-- استيراد حزمة الموقع

class DeviceInfoProvider {
  final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  final NetworkInfo _networkInfo = NetworkInfo();
  final Uuid _uuid = const Uuid();

  Future<String?> getIpAddress() async {
    try {
      return await _networkInfo.getWifiIP();
    } catch (e) {
      print('Could not get IP Address: $e');
      return 'Unknown IP';
    }
  }

  Future<String?> getOsUser() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfoPlugin.androidInfo;
        return androidInfo.model;
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfoPlugin.iosInfo;
        return iosInfo.name;
      }
    } catch (e) {
      print('Could not get OS User: $e');
    }
    return 'Unknown Device';
  }

  Future<String> getDeviceUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'device_unique_id';
    String? existingId = prefs.getString(key);
    if (existingId != null) {
      return existingId;
    } else {
      String newId = _uuid.v4();
      await prefs.setString(key, newId);
      return newId;
    }
  }

  /// **الدالة الجديدة لتحديد الموقع**
  /// Determines the current position of the device.
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }
}
