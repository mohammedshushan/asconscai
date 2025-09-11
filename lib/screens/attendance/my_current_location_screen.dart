import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../app_localizations.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';

class MyCurrentLocationScreen extends StatefulWidget {
  final UserModel user;
  const MyCurrentLocationScreen({super.key, required this.user});

  @override
  State<MyCurrentLocationScreen> createState() => _MyCurrentLocationScreenState();
}

class _MyCurrentLocationScreenState extends State<MyCurrentLocationScreen> {
  final LocationService _locationService = LocationService();

  Position? _currentPosition;
  String _currentAddress = "جاري تحديد الموقع...";
  String _currentTime = "";
  Timer? _timer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('hh:mm:ss a', 'ar').format(DateTime.now());
      });
    }
  }

  Future<void> _initializeLocation() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // التحقق من صلاحيات الموقع وتفعيله
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('location_service_disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('location_permission_denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('location_permission_denied_forever');
      }

      // جلب الموقع الحالي
      if (mounted) setState(() => _currentAddress = "جاري تحديد الموقع الدقيق...");
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      // جلب العنوان من الإحداثيات
      if (mounted) setState(() => _currentAddress = "جاري جلب تفاصيل العنوان...");
      final newAddress = await _locationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (mounted) {
        setState(() {
          _currentAddress = newAddress.isNotEmpty ? newAddress : "تعذر جلب اسم العنوان";
        });
      }

    } catch (e) {
      // (للمطور) طباعة الخطأ الفعلي
      print("Error in MyCurrentLocationScreen: $e");
      if (mounted) {
        setState(() {
          // تحديد رسالة خطأ آمنة بناءً على نوع الخطأ
          final errorString = e.toString();
          if (errorString.contains('location_service_disabled')) {
            _errorMessage = "خدمة الموقع غير مفعلة. يرجى تفعيل GPS والمحاولة مرة أخرى.";
          } else if (errorString.contains('location_permission_denied')) {
            _errorMessage = "تم رفض صلاحية الوصول للموقع. لا يمكن عرض الموقع الحالي.";
          } else if (errorString.contains('location_permission_denied_forever')) {
            _errorMessage = "تم رفض صلاحية الموقع بشكل دائم. يرجى تفعيلها من إعدادات التطبيق.";
          } else {
            _errorMessage = "فشل تحديد الموقع. يرجى التحقق من اتصالك بالإنترنت وتفعيل GPS.";
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2), // لون خلفية الجزء العلوي
      body: Stack(
        children: [
          // الجزء السفلي الأبيض
          Column(
            children: [
              // مساحة فارغة بنفس ارتفاع الجزء العلوي
              SizedBox(height: 250),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      // مساحة فارغة لترك مكان للكارت
                      const SizedBox(height: 110),
                      // الخريطة أو حالات الخطأ والتحميل
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _buildMapArea(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // الجزء العلوي الملون
          _buildTopSection(context, localizations),

          // كارت المعلومات الذي يتوسط الجزئين
          Positioned(
            top: 150, // تعديل الارتفاع ليتناسب مع التصميم
            left: 20,
            right: 20,
            child: _buildUserInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, AppLocalizations localizations) {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6C63FF), Color(0xFF357ABD)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              centerTitle: true,
              title: Text(
                localizations.translate('my_current_location') ?? 'موقعي الحالي',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final locale = Localizations.localeOf(context).languageCode;
    final today = DateFormat.yMMMMEEEEd(locale).format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // التاريخ والوقت
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.calendar_1, size: 16, color: Color(0xFF4A90E2)),
              const SizedBox(width: 8),
              Text(
                today,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4A90E2), fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              const Icon(Iconsax.clock, size: 16, color: Color(0xFF4A90E2)),
              const SizedBox(width: 8),
              Text(
                _currentTime,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4A90E2), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          // العنوان
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Iconsax.location, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isLoading ? "جاري التحميل..." : (_errorMessage ?? _currentAddress),
                  style: TextStyle(
                      fontSize: 14,
                      color: _errorMessage != null ? Colors.red.shade700 : Colors.black87,
                      fontWeight: FontWeight.w500,
                      height: 1.5
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          // الإحداثيات
          if (_currentPosition != null && _errorMessage == null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Long: ${_currentPosition!.longitude.toStringAsFixed(5)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4A90E2)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wrong_location_outlined, color: Colors.red.shade400, size: 60),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.red.shade700, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initializeLocation,
                icon: const Icon(Icons.refresh),
                label: const Text("إعادة المحاولة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: _currentPosition != null ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude) : const LatLng(30.58, 31.50), // Fallback center
            initialZoom: 17.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    width: 80,
                    height: 80,
                    child: Icon(Icons.location_pin, color: Colors.red.shade500, size: 50),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}