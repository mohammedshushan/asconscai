





import 'package:asconscai/screens/approvals/approvals_main_screen.dart';
import 'package:asconscai/screens/attendance/attendance_main_screen.dart';
import 'package:asconscai/screens/permissions/permissions_screen.dart';
import 'package:asconscai/screens/profile/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/user_model.dart';
import '../../models/module_model.dart';
import '../../services/api_service.dart';
import '../../services/vacation_service.dart';
import '../../services/loan_service.dart';
import '../vacations/vacations_screen.dart';
import '../loan/loans_screen.dart';
import '../../app_localizations.dart';
import '../../widgets/home_app_bar.dart';
import '../../utils/app_colors.dart';
import '../../widgets/info_dialog.dart';

class HomeScreen extends StatefulWidget {
  final UserModel user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final VacationService _vacationService = VacationService();
  final LoanService _loanService = LoanService();
  late Future<List<ModuleModel>> _modulesFuture;
  bool isLoading = false; // إضافة متغير لتتبع حالة التحميل

  @override
  void initState() {
    super.initState();
    _modulesFuture = _apiService.getModules();
    // إعادة تعيين حالة التحميل عند بدء الشاشة
    isLoading = false;
  }

  @override
  void dispose() {
    // التأكد من إغلاق أي dialogs مفتوحة
    if (isLoading) {
      isLoading = false;
    }
    super.dispose();
  }
  // دالة محسّنة للتعامل مع كل الوحدات مع معالجة أفضل للأخطاء
  void _handleModuleTap(ModuleModel module) async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    final localizations = AppLocalizations.of(context)!;
    final moduleName = module.nameEn.toLowerCase();

    // التأكد من إغلاق أي dialogs مفتوحة
    while (Navigator.of(context).canPop() && ModalRoute.of(context)?.isActive != true) {
      Navigator.of(context).pop();
    }

    // إظهار مؤشر تحميل محسن
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (BuildContext loadingContext) => PopScope(
        canPop: false,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 16),
                  Text('جاري التحميل...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      if (moduleName.contains('vacation')) {
        final hasVacationAccess = await _vacationService.checkVacationAccess(
            widget.user.usersCode.toString()
        );
          print('check is $hasVacationAccess');
        if (!mounted) return;

        // إغلاق مؤشر التحميل
        Navigator.of(context, rootNavigator: true).pop();

        if (!hasVacationAccess) {
          print('E2');
          _showAccessDeniedDialog(localizations.translate('no_vacation_privileges')!);
          return;
        }

        final balances = await _vacationService.getVacationBalance(
            widget.user.usersCode.toString()
        );
        print('balances is $balances');

        if (!mounted) return;


          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => VacationsScreen(user: widget.user)
            ),
          );


      }
    else if (moduleName.contains('permission')) {
    final hasLoanAccess = await _loanService.checkLoanAccess(
    widget.user.usersCode.toString()
    );
    if (!mounted) return;

    // إغلاق مؤشر التحميل
    Navigator.of(context, rootNavigator: true).pop();

    if (!hasLoanAccess) {

    _showAccessDeniedDialog(localizations.translate('no_loan_privileges')!);
    return;
    }

    if (!mounted) return;


    Navigator.push(
    context,
    MaterialPageRoute(
    builder: (context) => PermissionsScreen(user: widget.user)
    ),
    );

    }
      else if (moduleName.contains('loan')) {
        final hasLoanAccess = await _loanService.checkLoanAccess(
            widget.user.usersCode.toString()
        );

        if (!mounted) return;

        // إغلاق مؤشر التحميل
        Navigator.of(context, rootNavigator: true).pop();

        if (!hasLoanAccess) {
          _showAccessDeniedDialog(localizations.translate('no_loan_privileges')!);
          return;
        }

        final balances = await _vacationService.getVacationBalance(
            widget.user.usersCode.toString()
        );

        if (!mounted) return;


          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => LoansScreen(user: widget.user)
            ),
          );

      }
      else if(moduleName.contains('attendance')){

        // -->> ✅ الحل الرئيسي هنا <<--
        // نقوم بإغلاق مؤشر التحميل قبل الانتقال للصفحة
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        await Future.delayed(const Duration(milliseconds: 50)); // انتظار بسيط لضمان الإغلاق
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceMainScreen(user: widget.user)));


      }
    else if(moduleName.contains('profile')){
    // -->> ✅ الحل الرئيسي هنا <<--
    // نقوم بإغلاق مؤشر التحميل قبل الانتقال للصفحة
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    await Future.delayed(const Duration(milliseconds: 50)); // انتظار بسيط لضمان الإغلاق
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user.usersCode)));


    }
      else if(moduleName.contains('approval')){

        // -->> ✅ الحل الرئيسي هنا <<--
        // نقوم بإغلاق مؤشر التحميل قبل الانتقال للصفحة
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        await Future.delayed(const Duration(milliseconds: 50)); // انتظار بسيط لضمان الإغلاق
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => ApprovalsMainScreen(user: widget.user)));
      }
       else {
        if (!mounted) return;

        // إغلاق مؤشر التحميل
        Navigator.of(context, rootNavigator: true).pop();
        /*
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizations.translate('workInProgress')!),
            backgroundColor: const Color(0xFF6C63FF),
          ),
        );*/
      }

    } catch (e, stackTrace) { // أضفنا stackTrace لتتبع أفضل
      if (!mounted) return;

      // (مهم للمطور) طباعة الخطأ الفعلي في الـ Debug Console فقط
      // هذا السطر لن يظهر للمستخدم النهائي في نسخة الـ release
      print('An error occurred in _handleModuleTap: $e');
      print('Stack trace: $stackTrace');

      // إغلاق مؤشر التحميل في حالة الخطأ
      Navigator.of(context, rootNavigator: true).pop();

      // ✅ الحل: عرض رسالة خطأ عامة وثابتة للمستخدم
      _showInfoDialog(
        title: localizations.translate('error')!,
        // استخدم رسالة عامة من ملفات الترجمة أو رسالة ثابتة
        message: localizations.translate('general_error_message') ?? 'حدث خطأ ما، يرجى المحاولة مرة أخرى.',
        isSuccess: false,
      );
    } finally {

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
  // دالة منفصلة لإظهار رسالة عدم وجود صلاحية

  void _showAccessDeniedDialog(String message) {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context)!;

    // تأخير بسيط للتأكد من إغلاق الـ dialog السابق
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        useRootNavigator: true,
        builder: (context) => InfoDialog(
          title: localizations.translate('no_access_title')!,
          message: message,
          isSuccess: false,
          buttonText: localizations.translate('ok'),
        ),
      );
    });
  }
  // دالة منفصلة لإظهار الرسائل العامة
  void _showInfoDialog({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context)!;

    // تأخير بسيط للتأكد من إغلاق الـ dialog السابق
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: true,
        useRootNavigator: true,
        builder: (context) => InfoDialog(
          title: title,
          message: message,
          isSuccess: isSuccess,
          buttonText: localizations.translate('ok'),
        ),
      );
    });
  }

  IconData _getIconForModule(String moduleNameEn) {
    final name = moduleNameEn.toLowerCase();
    if (name.contains('profile')) return Icons.person_search_rounded;
    if (name.contains('employee')) return Icons.groups_2_rounded;
    if (name.contains('loan')) return Icons.account_balance_wallet_rounded;
    if (name.contains('vacation')) return Icons.deck_rounded;
    if (name.contains('attendance')) return Icons.fingerprint_rounded;
    if (name.contains('approval')) return Icons.fact_check_rounded;
    if (name.contains('report')) return Icons.donut_large_rounded;
    if (name.contains('permission')) return Icons.grid_view_rounded;
    return Icons.grid_view_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<List<ModuleModel>>(
        future: _modulesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خطأ في تحميل البيانات',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'يرجى المحاولة مرة أخرى',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _modulesFuture = _apiService.getModules();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                    ),
                    child: const Text(
                      'إعادة المحاولة',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد وحدات متاحة',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final modules = snapshot.data!;
          return CustomScrollView(
            slivers: [
              HomeAppBar(user: widget.user),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: AnimationLimiter(
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: modules.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemBuilder: (context, index) {
                        final module = modules[index];
                        final moduleName = isRtl ? module.nameAr : module.nameEn;
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: const Duration(milliseconds: 500),
                          columnCount: 3,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: _buildModuleCard(
                                context: context,
                                module: module,
                                title: moduleName,
                                icon: _getIconForModule(module.nameEn),
                                index: index,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required ModuleModel module,
    required String title,
    required IconData icon,
    required int index,
  }) {
    final pastelColors = [
      const Color(0xFFE3F2FD), const Color(0xFFFFF3E0), const Color(0xFFE8F5E9),
      const Color(0xFFFCE4EC), const Color(0xFFF3E5F5), const Color(0xFFE0F7FA),
    ];
    final iconColors = [
      const Color(0xFF1565C0), const Color(0xFFE65100), const Color(0xFF2E7D32),
      const Color(0xFFAD1457), const Color(0xFF6A1B9A), const Color(0xFF006064),
    ];
    final bgColor = pastelColors[index % pastelColors.length];
    final iconColor = iconColors[index % iconColors.length];

    return GestureDetector(
      onTap: isLoading ? null : () => _handleModuleTap(module),
      child: Opacity(
        opacity: isLoading ? 0.6 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: iconColor),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: iconColor.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



