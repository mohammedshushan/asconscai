import 'dart:async';
import 'dart:io';

import 'package:asconscai/screens/attendance/register_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../app_localizations.dart';
import '../../main.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../services/location_service.dart';
import 'attendance_months_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class AttendanceMainScreen extends StatefulWidget {
  final UserModel user;
  const AttendanceMainScreen({super.key, required this.user});

  @override
  State<AttendanceMainScreen> createState() => _AttendanceMainScreenState();
}

class _AttendanceMainScreenState extends State<AttendanceMainScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final LocationService _locationService = LocationService();
  late Future<Map<String, dynamic>> _dashboardDataFuture;
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hasInternet = true;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    _dashboardDataFuture = _fetchDashboardData();
    _setupConnectivityListener();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
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

      await _retryFetchData();
    } else if (!hasConnection) {
      setState(() {
        _hasInternet = false;
      });
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final response = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return response.isNotEmpty && response[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _retryFetchData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isRetrying = true;
        // إعادة تعيين الـ Future لجلب البيانات من جديد
        _dashboardDataFuture = _fetchDashboardData();
      });
      // ننتظر اكتمال الـ Future الجديد
      await _dashboardDataFuture;
    } catch (e) {
      // FutureBuilder سيعالج عرض الخطأ، يمكننا فقط طباعته هنا
      print("Error during manual retry: $e");
    } finally {
      if(mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  // -->> ✅ تم حذف دالة _getErrorMessage لأنها غير آمنة <<--

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    try {
      final String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final records = await _attendanceService.getAttendanceDetails(widget.user.usersCode, currentMonth);

      if (records.isEmpty) {
        return {'latestRecord': null, 'checkInDays': 0, 'location': 'لا توجد بيانات'};
      }

      records.sort((a, b) => b.recordTime.compareTo(a.recordTime));
      final AttendanceRecord latestRecord = records.first;

      final checkInDays = records
          .where((r) => r.state == 0)
          .map((r) => DateFormat('yyyy-MM-dd').format(r.workDay))
          .toSet()
          .length;

      String location;
      try {
        location = await _locationService.getAddressFromCoordinates(
          latestRecord.latitude,
          latestRecord.longitude,
        );
      } catch (e) {
        location = "خطأ في جلب العنوان";
      }

      return {
        'latestRecord': latestRecord,
        'checkInDays': checkInDays,
        'location': location,
      };
    } catch (e) {
      // FutureBuilder سيلتقط الخطأ ويعالجه
      rethrow;
    }
  }

  void _launchMaps(double lat, double lon) async {
    try {
      final List<String> mapUrls = [
        'google.navigation:q=$lat,$lon',
        'https://maps.google.com/?q=$lat,$lon',
        'geo:$lat,$lon?q=$lat,$lon',
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
      ];

      bool launched = false;

      for (String url in mapUrls) {
        try {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            launched = true;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (!launched) {
        final Uri fallbackUri = Uri.parse('https://maps.google.com/?q=$lat,$lon');
        await launchUrl(fallbackUri, mode: LaunchMode.inAppWebView);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح الخريطة. يرجى المحاولة مرة أخرى.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildModernAppBar(context, localizations),
          SliverToBoxAdapter(
            child: Column(
              children: [
                if (!_hasInternet && !_isRetrying)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.red.shade600, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "لا يوجد اتصال بالإنترنت",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _retryFetchData,
                          child: const Text("إعادة المحاولة"),
                        ),
                      ],
                    ),
                  ),
                if (_isRetrying)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                FutureBuilder<Map<String, dynamic>>(
                  future: _dashboardDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !_isRetrying) {
                      return _buildDashboardShimmer();
                    }
                    // -->> ✅ بداية الجزء الذي تم تعديله <<--
                    if (snapshot.hasError) {
                      // طباعة الخطأ الفعلي للمطور
                      print("Error in attendance dashboard FutureBuilder: ${snapshot.error}");
                      // عرض واجهة خطأ آمنة
                      return Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, color: Colors.orange.shade600, size: 40),
                              const SizedBox(height: 12),
                              Text(
                                localizations.translate('failed_to_load_data') ?? 'فشل تحميل البيانات',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _retryFetchData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade600,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(localizations.translate('retry') ?? "إعادة المحاولة"),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    // -->> 🔚 نهاية الجزء الذي تم تعديله <<--

                    if (!snapshot.hasData || snapshot.data == null) {
                      return _buildDashboardShimmer(); // إظهار الشيمر إذا لم تكن البيانات جاهزة بعد
                    }

                    final data = snapshot.data!;
                    return _buildDashboard(data, localizations);
                  },
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: 20),
            sliver: _buildMenuItems(localizations, screenWidth, context),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(Map<String, dynamic> data, AppLocalizations localizations) {
    final AttendanceRecord? record = data['latestRecord'];
    final int checkInDays = data['checkInDays'];
    final String location = data['location'];
    final isCheckIn = record?.state == 0;
    final locale = Localizations.localeOf(context).languageCode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 186,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isCheckIn
                          ? [Colors.green.shade400, Colors.green.shade300]
                          : [Colors.orange.shade400, Colors.orange.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isCheckIn ? Colors.green : Colors.orange).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isCheckIn ? Iconsax.login_1 : Iconsax.logout_1,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.translate('last_action') ?? 'آخر بصمة',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        record != null
                            ? (isCheckIn
                            ? localizations.translate('check_in') ?? 'دخول'
                            : localizations.translate('check_out') ?? 'خروج')
                            : 'لا يوجد',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (record != null) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('EEEE',locale).format(record.recordTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('yyyy/MM/dd').format(record.recordTime),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('h:mm a').format(record.recordTime),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ] else ...[
                        Text(
                          '-',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  height: 186,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [const Color(0xFF6C5CE7).withOpacity(.5), const Color(0xFF5A4FCF).withOpacity(.5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Iconsax.calendar_tick,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.translate('attendance_days') ?? 'أيام الحضور',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$checkInDays',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.translate('day') ?? 'يوم',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 15, thickness: 1),
          Text(
            localizations.translate('last_location') ?? 'آخر موقع للبصمة',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Iconsax.location, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: record != null ? () => _launchMaps(record.latitude, record.longitude) : null,
                  child: Text(
                    location,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4277D3),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardShimmer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 150,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16)
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16)
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 10),
          Container(
            width: 120,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildMenuItems(AppLocalizations localizations, double screenWidth, BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': localizations.translate('register_attendance')!,
        'icon': Iconsax.clipboard_tick,
        'primaryColor': const Color(0xFF6C5CE7),
        'onTap': () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterAttendanceScreen(user: widget.user),
            ),
          );

          if (result == true && mounted) {
            _retryFetchData();
          }
        },
        'enabled': true,
      },
      {
        'title': localizations.translate('my_current_location')!,
        'icon': Icons.location_pin,
        'primaryColor': const Color(0xFF00B894),
        'onTap': () {},
        'enabled': true,
      },
      {
        'title': localizations.translate('my_attendance_log')!,
        'icon': Iconsax.document_text_1,
        'primaryColor': const Color(0xFF0984E3),
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceMonthsScreen(user: widget.user)));
        },
        'enabled': true,
      },
      {
        'title': localizations.translate('my_shift_schedule')!,
        'icon': Iconsax.calendar_1,
        'primaryColor': const Color(0xFFE17055),
        'onTap': () {},
        'enabled': true,
      },
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final item = menuItems[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 800),
            child: SlideAnimation(
              verticalOffset: 100.0,
              curve: Curves.easeOutBack,
              child: FadeInAnimation(
                curve: Curves.easeIn,
                child: Container(
                  margin: EdgeInsets.only(bottom: screenHeight * 0.025),
                  child: _buildResponsiveCard(context: context, item: item, screenWidth: screenWidth, screenHeight: screenHeight),
                ),
              ),
            ),
          );
        },
        childCount: menuItems.length,
      ),
    );
  }

  Widget _buildResponsiveCard({
    required BuildContext context,
    required Map<String, dynamic> item,
    required double screenWidth,
    required double screenHeight,
  }) {
    final isTablet = screenWidth > 600;
    final cardHeight = isTablet ? screenHeight * 0.12 : screenHeight * 0.10;

    return GestureDetector(
      onTap: item['enabled'] ? item['onTap'] as void Function()? : null,
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: (item['primaryColor'] as Color).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.02),
              child: Row(
                children: [
                  Container(
                    width: isTablet ? 70 : 60,
                    height: isTablet ? 70 : 60,
                    decoration: BoxDecoration(color: item['enabled'] ? item['primaryColor'] as Color : Colors.grey.shade400, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: item['enabled'] ? (item['primaryColor'] as Color).withOpacity(0.3) : Colors.grey.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6))]),
                    child: Icon(item['icon'] as IconData, color: Colors.white, size: isTablet ? 32 : 28),
                  ),
                  SizedBox(width: screenWidth * 0.04),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Text(item['title'] as String, style: TextStyle(fontSize: isTablet ? 18 : 16, fontWeight: FontWeight.bold, color: item['enabled'] ? const Color(0xFF2D3748) : Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis)],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: item['enabled'] ? item['primaryColor'] as Color : Colors.grey.shade400, size: isTablet ? 20 : 16)
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildModernAppBar(BuildContext context, AppLocalizations localizations) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF6C63FF),
      pinned: true,
      centerTitle: true,
      automaticallyImplyLeading: true,
      iconTheme: const IconThemeData(color: Colors.white),
      expandedHeight: 80.0,
      elevation: 2,
      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(80), bottomRight: Radius.circular(80))),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(localizations.translate('attendance')!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language_outlined, color: Colors.white, size: 26),
          onPressed: () {
            final currentLocale = Localizations.localeOf(context);
            final newLocale = currentLocale.languageCode == 'en' ? const Locale('ar', '') : const Locale('en', '');
            MyApp.of(context)?.changeLanguage(newLocale);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}