import 'dart:async';
import 'dart:io';

import 'package:asconscai/utils/device_info_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../app_localizations.dart';
import '../../main.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import '../../widgets/status_dialogpart2.dart';

class RegisterAttendanceScreen extends StatefulWidget {
  final UserModel user;
  const RegisterAttendanceScreen({super.key, required this.user});

  @override
  State<RegisterAttendanceScreen> createState() => _RegisterAttendanceScreenState();
}

class _RegisterAttendanceScreenState extends State<RegisterAttendanceScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();

  int _selectedState = 0;
  Position? _currentPosition;
  String _currentAddress = "جاري تحديد الموقع...";
  String _currentIp = "جاري جلب IP...";
  String _currentTime = "";
  Timer? _timer;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _lastSerial = 0;
  bool _hasInternet = true;
  bool _isRetrying = false;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _setupConnectivityListener();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('hh:mm:ss a', 'ar').format(DateTime.now());
      });
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _handleConnectivityChange(results);
    });
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) async {
    bool hasConnection = results.any((result) => result != ConnectivityResult.none);

    if (!mounted) return;

    if (hasConnection && !_hasInternet) {
      setState(() {
        _hasInternet = true;
        _isRetrying = true;
      });

      await Future.delayed(const Duration(seconds: 2));

      bool hasRealInternet = await _checkInternetConnection();
      if (!hasRealInternet) {
        if (mounted) {
          setState(() {
            _hasInternet = false;
            _isRetrying = false;
          });
        }
        return;
      }

      await _retryInitialization();
    } else if (!hasConnection) {
      setState(() {
        _hasInternet = false;
      });
    }
  }

  Future<void> _retryInitialization() async {
    if (!mounted) return;

    try {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _isRetrying = true;
        });
      }

      await _determinePosition();
      _currentIp = await DeviceInfoProvider().getIpAddress() ?? 'فشل جلب IP';

      final String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final List<AttendanceRecord> records = await _attendanceService.getAttendanceDetails(
          widget.user.usersCode,
          currentMonth
      );

      if (records.isNotEmpty) {
        records.sort((a,b) => b.ser.compareTo(a.ser));
        _lastSerial = records.first.ser;
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRetrying = false;
          _hasInternet = true;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRetrying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // -->> ✅ بداية التعديل الوحيد والدقيق <<--
  String _getErrorMessage(dynamic error) {
    // (للمطور) طباعة الخطأ الفعلي والهام في الكونسول لتشخيص المشاكل
    print("An error was handled in RegisterAttendanceScreen: $error");

    // إرجاع رسالة عامة وآمنة وثابتة دائمًا، بغض النظر عن نوع الخطأ
    return "حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.";
  }
  // -->> 🔚 نهاية التعديل الوحيد والدقيق <<--

  Future<void> _initializeScreen() async {
    setState(() { _isLoading = true; });
    try {
      await _determinePosition();

      final String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final List<AttendanceRecord> records = await _attendanceService.getAttendanceDetails(
          widget.user.usersCode, currentMonth);
      if (records.isNotEmpty) {
        records.sort((a,b) => b.ser.compareTo(a.ser));
        _lastSerial = records.first.ser;
      }

      _currentIp = await DeviceInfoProvider().getIpAddress() ?? 'فشل جلب IP';

    } catch (e) {
      if(mounted) {
        StatusDialog.show(context, _getErrorMessage(e), isSuccess: false);
        setState(() {
          _currentAddress = "فشل تحديد الموقع";
          _currentIp = "فشل جلب IP";
          _hasInternet = false;
        });
      }
    } finally {
      if(mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        bool opened = await Geolocator.openLocationSettings();
        if (!opened) {
          throw Exception('خدمة الموقع غير مفعلة. يرجى تفعيل GPS من إعدادات الجهاز');
        }
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('خدمة الموقع غير مفعلة. يرجى تفعيل GPS من إعدادات الجهاز');
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('تم رفض صلاحية الموقع. يرجى قبول الصلاحية للمتابعة');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        bool opened = await Geolocator.openAppSettings();
        throw Exception('صلاحية الموقع مرفوضة نهائياً. يرجى تفعيلها من إعدادات التطبيق');
      }

      if (mounted) {
        setState(() {
          _currentAddress = "جاري تحديد الموقع الدقيق...";
        });
      }

      _currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
            timeLimit: Duration(seconds: 15),
          ));

      if (mounted) {
        setState(() {
          _currentAddress = "جاري جلب تفاصيل العنوان...";
        });
      }

      // التعديل الرئيسي هنا - جلب العنوان مع معالجة أفضل للأخطاء
      try {
        final newAddress = await _locationService.getAddressFromCoordinates(
            _currentPosition!.latitude,
            _currentPosition!.longitude
        );

        if (mounted && newAddress.isNotEmpty) {
          setState(() {
            _currentAddress = newAddress;
          });
        } else if (mounted) {
          setState(() {
            _currentAddress = "Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}";
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _currentAddress = "Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}";
          });
        }
      }

    } on LocationServiceDisabledException {
      throw Exception('خدمة الموقع معطلة. يرجى تفعيلها من إعدادات الجهاز');
    } on PermissionDeniedException {
      throw Exception('تم رفض صلاحية الموقع');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        Position? lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          _currentPosition = lastPosition;
          if (mounted) {
            setState(() {
              _currentAddress = "Lat: ${lastPosition.latitude.toStringAsFixed(6)}, Lng: ${lastPosition.longitude.toStringAsFixed(6)} (آخر موقع معروف)";
            });
          }
        } else {
          throw Exception('انتهت مهلة تحديد الموقع. تأكد من وجودك في مكان مفتوح وحاول مرة أخرى');
        }
      } else {
        rethrow;
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (_currentPosition == null) {
      StatusDialog.show(context, "لا يمكن تسجيل البصمة بدون تحديد الموقع.", isSuccess: false);
      return;
    }

    setState(() { _isSubmitting = true; });
    final localizations = AppLocalizations.of(context)!;

    try {
      final now = DateTime.now();
      final data = {
        "ser": _lastSerial + 1,
        "emp_code": widget.user.usersCode,
        "comp_emp_code": widget.user.compEmpCode,
        "login_ip": _currentIp,
        "latitude": _currentPosition!.latitude,
        "longitude": _currentPosition!.longitude,
        "work_day": DateFormat('yyyy-MM-dd').format(now),
        "record_time": "${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(now)}Z",
        "type": 6,
        "state": _selectedState
      };

      await _attendanceService.postAttendanceRecord(widget.user.usersCode, data);

      if(mounted) {
        StatusDialog.show(context, localizations.translate('attendance_recorded_successfully')!, isSuccess: true, duration: 2);
        Navigator.pop(context,true);
      }

    } catch(e) {
      if(mounted) {
        StatusDialog.show(context, _getErrorMessage(e), isSuccess: false);
      }
    } finally {
      if(mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final today = DateFormat.yMMMMEEEEd('ar').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF4A90E2),
      body: Stack(
        children: [
          Column(
            children: [
              _buildTopSection(context, localizations, today),
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
                      const SizedBox(height: 80),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: _buildStateToggle(localizations),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: _buildMapArea(localizations),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 100,
            left: 20,
            right: 20,
            child: _buildUserInfoCard(),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            left: MediaQuery.of(context).size.width / 2 - 40,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 37,
                backgroundImage: AssetImage('assets/images/photo.jpg'),
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          if (_isRetrying)
            Positioned(
              top: MediaQuery.of(context).padding.top + 200,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue.shade600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "جاري تحديث البيانات...",
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (!_hasInternet && !_isLoading && !_isRetrying)
            Positioned(
              top: MediaQuery.of(context).padding.top + 200,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.wifi_off,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentPosition == null
                                ? "فشل في تحديد الموقع وجلب البيانات"
                                : "لا يوجد اتصال بالإنترنت",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          await _retryInitialization();
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          "إعادة المحاولة",
                          style: TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_currentPosition == null && !_isLoading && !_isRetrying)
            Positioned(
              top: MediaQuery.of(context).padding.top + 340,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "نصائح لتحسين تحديد الموقع:",
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "• تأكد من تفعيل GPS في الإعدادات\n"
                          "• اخرج إلى مكان مفتوح (بعيداً عن المباني)\n"
                          "• تأكد من وجود اتصال إنترنت جيد\n"
                          "• أعد تشغيل التطبيق إذا لزم الأمر",
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, AppLocalizations localizations, String today) {
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
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.language_outlined, color: Colors.white),
                  onPressed: () => MyApp.of(context)?.changeLanguage(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? const Locale('ar')
                          : const Locale('en')
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final locale = Localizations.localeOf(context).languageCode;
    final today = DateFormat.yMMMMEEEEd(locale).format(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      padding: const EdgeInsets.only(top: 55, bottom: 20, left: 20, right: 20),
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
          Text(
            locale == 'ar' ? widget.user.empName : widget.user.empNameE ?? widget.user.empName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                today,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: 8),
              Text(
                _currentTime,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4A90E2),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _isLoading ? "جاري التحميل..." : _currentAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_currentAddress.contains("Lat:") && !_isLoading)
                IconButton(
                  icon: Icon(Icons.refresh, size: 16, color: Colors.blue),
                  onPressed: _determinePosition,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateToggle(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModernToggleButton(
              label: localizations.translate('check_in')!,
              icon: Iconsax.login_1,
              isSelected: _selectedState == 0,
              onTap: () => setState(() => _selectedState = 0),
              color: const Color(0xFF4CAF50),
            ),
          ),
          Expanded(
            child: _buildModernToggleButton(
              label: localizations.translate('check_out')!,
              icon: Iconsax.logout_1,
              isSelected: _selectedState == 1,
              onTap: () => setState(() => _selectedState = 1),
              color: const Color(0xFFFF6B6B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 18,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapArea(AppLocalizations localizations) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _isLoading
            ? Container(
          color: Colors.grey.shade100,
          child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF4A90E2))
          ),
        )
            : Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : LatLng(0, 0),
                initialZoom: 16.0,
                onMapReady: () {
                  if (_currentPosition != null) {
                    _updateLocationAddress();
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
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
                        width: 60,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_pin,
                            color: Color(0xFFFF6B6B),
                            size: 35,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0C73DA).withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onLongPress: _submitAttendance,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(22),
                      backgroundColor: const Color(0xFF6C63FF),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(localizations.translate('act')!),
                          backgroundColor: const Color(0xFFEE0342),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.fingerprint,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateLocationAddress() async {
    if (_currentPosition == null) return;

    try {
      final newAddress = await _locationService.getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      if (mounted && newAddress.isNotEmpty) {
        setState(() {
          _currentAddress = newAddress;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}";
        });
      }
    }
  }
}