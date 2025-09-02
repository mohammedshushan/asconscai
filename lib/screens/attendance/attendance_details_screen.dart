/*
import 'package:asconscai/widgets/attendance/empty_state_widget.dart';
import 'package:asconscai/widgets/attendance/error_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../app_localizations.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../widgets/custom_app_bar.dart';


class AttendanceDetailsScreen extends StatefulWidget {
  final UserModel user;
  final String yearMonth;
  final String displayMonth;

  const AttendanceDetailsScreen({
    super.key,
    required this.user,
    required this.yearMonth,
    required this.displayMonth,
  });

  @override
  State<AttendanceDetailsScreen> createState() => _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen> {
  late Future<Map<DateTime, List<AttendanceRecord>>> _groupedRecordsFuture;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _groupedRecordsFuture = _fetchAndGroupRecords();
  }

  Future<Map<DateTime, List<AttendanceRecord>>> _fetchAndGroupRecords() async {
    final records = await _attendanceService.getAttendanceDetails(
        widget.user.usersCode, widget.yearMonth);

    // تجميع السجلات حسب اليوم
    final Map<DateTime, List<AttendanceRecord>> grouped = {};
    for (var record in records) {
      // تجاهل الوقت للحصول على اليوم فقط
      final day = DateUtils.dateOnly(record.workDay);
      if (grouped[day] == null) {
        grouped[day] = [];
      }
      grouped[day]!.add(record);
    }

    // فرز السجلات داخل كل يوم حسب الوقت
    grouped.forEach((day, dayRecords) {
      dayRecords.sort((a, b) => a.recordTime.compareTo(b.recordTime));
    });

    // فرز الأيام نفسها (من الأحدث للأقدم)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final Map<DateTime, List<AttendanceRecord>> sortedGrouped = { for (var k in sortedKeys) k: grouped[k]! };

    return sortedGrouped;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(title: widget.displayMonth),
      body: FutureBuilder<Map<DateTime, List<AttendanceRecord>>>(
        future: _groupedRecordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF11998e)));
          }
          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: '${localizations.translate('error_loading_details')!}: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _groupedRecordsFuture = _fetchAndGroupRecords();
                });
              },
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              message: localizations.translate('no_details_for_this_month')!,
              icon: Iconsax.calendar_remove,
            );
          }

          final groupedRecords = snapshot.data!;
          final days = groupedRecords.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final dayRecords = groupedRecords[day]!;

              // تنسيق التاريخ ليكون "اسم اليوم، اليوم من الشهر"
              final dayFormatted = DateFormat.yMMMMEEEEd(localizations.locale.languageCode).format(day);

              return _buildDayCard(dayFormatted, dayRecords, localizations);
            },
          );
        },
      ),
    );
  }

  Widget _buildDayCard(String dayFormatted, List<AttendanceRecord> records, AppLocalizations localizations) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayFormatted,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF11998e)),
            ),
            const Divider(height: 24),
            ...List.generate(records.length, (index) {
              final record = records[index];
              final isFirst = index == 0;
              final isLast = index == records.length - 1;
              return _buildTimelineTile(record, isFirst, isLast, localizations);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineTile(AttendanceRecord record, bool isFirst, bool isLast, AppLocalizations localizations) {
    final isCheckIn = record.state == 0;
    final title = isCheckIn ? localizations.translate('check_in')! : localizations.translate('check_out')!;
    final color = isCheckIn ? Colors.green.shade600 : Colors.orange.shade700;
    final icon = isCheckIn ? Iconsax.login_1 : Iconsax.logout_1;
    final timeFormatted = DateFormat.jm().format(record.recordTime); // format for "5:08 PM"

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(color: Colors.grey.shade300),
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
      endChild: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              timeFormatted,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
*/

import 'package:asconscai/widgets/attendance/empty_state_widget.dart';
import 'package:asconscai/widgets/attendance/error_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../../app_localizations.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';
import '../../widgets/custom_app_bar.dart';

class AttendanceDetailsScreen extends StatefulWidget {
  final UserModel user;
  final String yearMonth;
  final String displayMonth;

  const AttendanceDetailsScreen({
    super.key,
    required this.user,
    required this.yearMonth,
    required this.displayMonth,
  });

  @override
  State<AttendanceDetailsScreen> createState() => _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen> {
  late Future<Map<DateTime, List<AttendanceRecord>>> _groupedRecordsFuture;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _groupedRecordsFuture = _fetchAndGroupRecords();
  }

  Future<Map<DateTime, List<AttendanceRecord>>> _fetchAndGroupRecords() async {
    final records = await _attendanceService.getAttendanceDetails(
        widget.user.usersCode, widget.yearMonth);

    // تجميع السجلات حسب اليوم
    final Map<DateTime, List<AttendanceRecord>> grouped = {};
    for (var record in records) {
      // تجاهل الوقت للحصول على اليوم فقط
      final day = DateUtils.dateOnly(record.workDay);
      if (grouped[day] == null) {
        grouped[day] = [];
      }
      grouped[day]!.add(record);
    }

    // فرز السجلات داخل كل يوم حسب الوقت
    grouped.forEach((day, dayRecords) {
      dayRecords.sort((a, b) => a.recordTime.compareTo(b.recordTime));
    });

    // فرز الأيام نفسها (من الأحدث للأقدم)
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final Map<DateTime, List<AttendanceRecord>> sortedGrouped = { for (var k in sortedKeys) k: grouped[k]! };

    return sortedGrouped;
  }

  // دالة لحساب إجمالي ساعات العمل لليوم
  Duration _calculateWorkHours(List<AttendanceRecord> records) {
    if (records.length < 2) return Duration.zero;

    DateTime? checkIn;
    DateTime? checkOut;

    for (var record in records) {
      if (record.state == 0) { // Check in
        checkIn = record.recordTime;
      } else if (record.state == 1 && checkIn != null) { // Check out
        checkOut = record.recordTime;
        break;
      }
    }

    if (checkIn != null && checkOut != null) {
      return checkOut.difference(checkIn);
    }

    return Duration.zero;
  }

  // دالة لتحديد لون اليوم بناءً على نوع اليوم وحالة الحضور
  Color _getDayColor(DateTime day, List<AttendanceRecord> records) {
    final isWeekend = day.weekday == 5 || day.weekday == 6; // جمعة وسبت

    if (isWeekend) {
      return const Color(0xFF9C27B0); // بنفسجي للعطلة
    }

    final workHours = _calculateWorkHours(records);
    if (workHours.inHours >= 8) {
      return const Color(0xFF4CAF50); // أخضر ليوم عمل كامل
    } else if (workHours.inHours >= 4) {
      return const Color(0xFF2196F3); // أزرق ليوم عمل جزئي
    } else if (records.isNotEmpty) {
      return const Color(0xFFFF9800); // برتقالي لحضور قصير
    }

    return const Color(0xFFE91E63); // وردي لعدم الحضور
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(title: widget.displayMonth),
      body: FutureBuilder<Map<DateTime, List<AttendanceRecord>>>(
        future: _groupedRecordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF11998e).withOpacity(0.1),
                          const Color(0xFF38bcb4).withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF11998e),
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'جاري تحميل تفاصيل الحضور...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasError) {
            return ErrorStateWidget(
              message: '${localizations.translate('error_loading_details')!}: ${snapshot.error}',
              onRetry: () {
                setState(() {
                  _groupedRecordsFuture = _fetchAndGroupRecords();
                });
              },
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              message: localizations.translate('no_details_for_this_month')!,
              icon: Iconsax.calendar_remove,
            );
          }

          final groupedRecords = snapshot.data!;
          final days = groupedRecords.keys.toList();
          final totalRecords = groupedRecords.values.fold(0, (sum, records) => sum + records.length);
          final totalWorkingDays = groupedRecords.length;

          return CustomScrollView(
            slivers: [
              // Header Statistics
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          icon: Iconsax.calendar_tick,
                          title: 'أيام العمل',
                          value: totalWorkingDays.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Iconsax.document_text,
                          title: 'إجمالي السجلات',
                          value: totalRecords.toString(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: Iconsax.clock,
                          title: 'المتوسط/يوم',
                          value: totalWorkingDays > 0 ?
                          (totalRecords / totalWorkingDays).toStringAsFixed(1) : '0',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Days List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final day = days[index];
                      final dayRecords = groupedRecords[day]!;
                      final dayFormatted = DateFormat.yMMMMEEEEd(localizations.locale.languageCode).format(day);
                      final dayColor = _getDayColor(day, dayRecords);
                      final workHours = _calculateWorkHours(dayRecords);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Day Header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    dayColor.withOpacity(0.1),
                                    dayColor.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 25,
                                    height: 25,
                                    decoration: BoxDecoration(
                                      color: dayColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Iconsax.calendar_1,
                                      color: dayColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dayFormatted,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: dayColor,
                                          ),
                                        ),
                                        if (workHours.inMinutes > 0)
                                          Text(
                                            'ساعات العمل: ${workHours.inHours}:${(workHours.inMinutes % 60).toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: dayColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${dayRecords.length} سجل',
                                      style: TextStyle(
                                        color: dayColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Timeline Records
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: List.generate(dayRecords.length, (recordIndex) {
                                  final record = dayRecords[recordIndex];
                                  final isFirst = recordIndex == 0;
                                  final isLast = recordIndex == dayRecords.length - 1;
                                  return _buildTimelineTile(record, isFirst, isLast, localizations);
                                }),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: days.length,
                  ),
                ),
              ),

              // Bottom Spacing
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineTile(AttendanceRecord record, bool isFirst, bool isLast, AppLocalizations localizations) {
    final isCheckIn = record.state == 0;
    final title = isCheckIn ? localizations.translate('check_in')! : localizations.translate('check_out')!;
    final color = isCheckIn ? const Color(0xFF4CAF50) : const Color(0xFFFF6B35);
    final icon = isCheckIn ? Iconsax.login_1 : Iconsax.logout_1;
    final timeFormatted = DateFormat.jm().format(record.recordTime);

    return TimelineTile(
      isFirst: isFirst,
      isLast: isLast,
      beforeLineStyle: LineStyle(
        color: Colors.grey.shade200,
        thickness: 2,
      ),
      afterLineStyle: LineStyle(
        color: Colors.grey.shade200,
        thickness: 2,
      ),
      indicatorStyle: IndicatorStyle(
        width: 40,
        height: 40,
        indicator: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color,
                color.withOpacity(0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
      endChild: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Iconsax.clock,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeFormatted,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                isCheckIn ? 'دخول' : 'خروج',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}