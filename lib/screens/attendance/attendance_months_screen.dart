
import 'package:asconscai/widgets/custom_app_bar.dart';
import 'package:asconscai/widgets/attendance/empty_state_widget.dart';
import 'package:asconscai/widgets/attendance/error_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import '../../app_localizations.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/attendance_service.dart';

import 'attendance_details_screen.dart';

class AttendanceMonthsScreen extends StatefulWidget {
  final UserModel user;
  const AttendanceMonthsScreen({super.key, required this.user});

  @override
  State<AttendanceMonthsScreen> createState() => _AttendanceMonthsScreenState();
}

class _AttendanceMonthsScreenState extends State<AttendanceMonthsScreen> {
  late Future<List<AttendanceMonthSummary>> _monthsFuture;
  final AttendanceService _attendanceService = AttendanceService();

  @override
  void initState() {
    super.initState();
    _monthsFuture = _attendanceService.getAttendanceMonths(widget.user.usersCode);
  }

  // دالة لتحويل رقم الشهر إلى اسم الشهر حسب اللغة
  String getMonthName(int month, BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    // إنشاء تاريخ وهمي للحصول على اسم الشهر
    DateTime date = DateTime(DateTime.now().year, month);
    return DateFormat.MMMM(locale).format(date);
  }

  // دالة لتحديد لون الشهر بناءً على عدد السجلات
  Color _getMonthColor(int recordCount) {
    if (recordCount >= 20) return const Color(0xFF00C853); // أخضر للحضور المتميز
    if (recordCount >= 10) return const Color(0xFF2196F3); // أزرق للحضور الجيد
    if (recordCount >= 5) return const Color(0xFFFF9800); // برتقالي للحضور المتوسط
    return const Color(0xFFE91E63); // وردي للحضور القليل
  }

  // دالة لتحديد أيقونة الشهر بناءً على عدد السجلات
  IconData _getMonthIcon(int recordCount) {
    if (recordCount >= 40) return Iconsax.medal_star;
    if (recordCount >= 20) return Iconsax.calendar_tick;
    if (recordCount >= 10) return Iconsax.calendar;
    return Iconsax.calendar_remove;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(title: localizations.translate('my_attendance_log')!),
      body: FutureBuilder<List<AttendanceMonthSummary>>(
        future: _monthsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF11998e).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF11998e),
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'جاري تحميل البيانات...',
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
              message: localizations.translate('error_loading_data')!,
              onRetry: () {
                setState(() {
                  _monthsFuture = _attendanceService.getAttendanceMonths(widget.user.usersCode);
                });
              },
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              message: localizations.translate('no_attendance_records_found')!,
              icon: Iconsax.document_cloud,
            );
          }

          final months = snapshot.data!;
          return AnimationLimiter(
            child: CustomScrollView(
              slivers: [
                // Header Statistics
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF11998e), Color(0xFF38bcb4)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF11998e).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            Iconsax.chart_square,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إجمالي الشهور المسجلة',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${months.length} شهر',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${months.fold(0, (sum, month) => sum + month.recordCount)} سجل',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Months List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final monthSummary = months[index];
                        final monthName = getMonthName(monthSummary.workMonth, context);
                        final monthColor = _getMonthColor(monthSummary.recordCount);
                        final monthIcon = _getMonthIcon(monthSummary.recordCount);

                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 600),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
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
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        PageRouteBuilder(
                                          pageBuilder: (context, animation, secondaryAnimation) =>
                                              AttendanceDetailsScreen(
                                                user: widget.user,
                                                yearMonth: monthSummary.yearMonth,
                                                displayMonth: '$monthName ${monthSummary.workYear}',
                                              ),
                                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                            const begin = Offset(1.0, 0.0);
                                            const end = Offset.zero;
                                            const curve = Curves.easeInOutCubic;

                                            var tween = Tween(begin: begin, end: end).chain(
                                              CurveTween(curve: curve),
                                            );

                                            return SlideTransition(
                                              position: animation.drive(tween),
                                              child: child,
                                            );
                                          },
                                          transitionDuration: const Duration(milliseconds: 400),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        children: [
                                          // Month Icon
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: monthColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: monthColor.withOpacity(0.3),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: Icon(
                                              monthIcon,
                                              color: monthColor,
                                              size: 28,
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Month Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$monthName ${monthSummary.workYear}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: monthColor.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        '${monthSummary.recordCount} ${localizations.translate('records_count')}',
                                                        style: TextStyle(
                                                          color: monthColor,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    if (monthSummary.recordCount >= 40)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFFD700),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: const Text(
                                                          '⭐ متميز',
                                                          style: TextStyle(
                                                            color: Color(0xFF8B4513),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Arrow and Statistics
                                          Column(
                                            children: [
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF11998e).withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.arrow_forward_ios_rounded,
                                                  color: Color(0xFF11998e),
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: monthColor,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: months.length,
                    ),
                  ),
                ),

                // Bottom Spacing
                const SliverToBoxAdapter(
                  child: SizedBox(height: 20),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}