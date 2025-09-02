import 'package:asconscai/screens/approvals/pending_permissions_screen.dart'; // ### إضافة جديدة
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../app_localizations.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../services/approvals_service.dart';
import '../../widgets/status_dialogpart2.dart';
import 'pending_vacations_screen.dart';

class ApprovalsMainScreen extends StatefulWidget {
  final UserModel user;
  const ApprovalsMainScreen({super.key, required this.user});

  @override
  State<ApprovalsMainScreen> createState() => _ApprovalsMainScreenState();
}

class _ApprovalsMainScreenState extends State<ApprovalsMainScreen> {
  final ApprovalsService _approvalsService = ApprovalsService();
  late Future<int> _pendingVacationsCount;
  late Future<int> _pendingPermissionsCount; // ### إضافة جديدة

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  void _loadCounts() {
    setState(() {
      _pendingVacationsCount = _approvalsService.getPendingVacationRequests(widget.user.usersCode.toString()).then((list) => list.length);
      _pendingPermissionsCount = _approvalsService.getPendingPermissionsCount(widget.user.usersCode.toString()); // ### إضافة جديدة
    });
  }

  Future<void> _navigateTo(BuildContext context, Widget page) async {
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (!connectivityResult.contains(ConnectivityResult.none)) {
      if (mounted) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        // تحديث العدادات عند العودة من أي صفحة
        _loadCounts();
      }
    } else {
      if (mounted) {
        StatusDialog.show(context, AppLocalizations.of(context)!.translate('no_internet_connection')!, isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: RefreshIndicator(
        onRefresh: () async => _loadCounts(),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context, localizations),
            SliverToBoxAdapter(child: _buildDashboard(localizations)),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: _buildServicesList(context, localizations),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context, AppLocalizations localizations) {
    return SliverAppBar(
      backgroundColor: const Color(0xFF6C63FF),
      pinned: true,
      expandedHeight: 80.0,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(90),
          bottomRight: Radius.circular(90),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          localizations.translate('approvals_management')!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        titlePadding: const EdgeInsets.only(bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language_outlined, color: Colors.white),
          onPressed: () => MyApp.of(context)?.changeLanguage(Localizations.localeOf(context).languageCode == 'en' ? const Locale('ar') : const Locale('en')),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDashboard(AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(
        children: [
          _buildDashboardCard(
            context:context,
            title: localizations.translate('vacation_requests')!,
            future: _pendingVacationsCount,
            icon: Iconsax.airplane,
            color: const Color(0xFF00B4DB).withOpacity(.5),
          ),
          const SizedBox(width: 16),
          _buildDashboardCard(
            context:context,
            title: localizations.translate('loan_requests')!,
            future: Future.value(5), // لا يزال ثابت كما طلبت
            icon: Iconsax.dollar_circle,
            color: const Color(0xFF00CDAC).withOpacity(.5),
          ),
          const SizedBox(width: 16),
          // ### START: التعديل الرئيسي هنا ###
          _buildDashboardCard(
            context:context,
            title: localizations.translate('permission_requests')!,
            future: _pendingPermissionsCount, // تم التغيير
            icon: Iconsax.clock,
            color: const Color(0xFFEE0342).withOpacity(.5),
          ),
          // ### END: التعديل الرئيسي هنا ###
        ],
      ),
    );
  }

  // باقي الكود كما هو بدون تغيير
  // ...
  // =========================================================================

  Widget _buildDashboardCard({
    required BuildContext context,
    required String title,
    required Future<int> future,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 130,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FutureBuilder<int>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                      }
                      return Text(
                        snapshot.data?.toString() ?? '0',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                  Text(title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 12,fontWeight:FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServicesList(BuildContext context, AppLocalizations localizations) {
    final services = [
      {
        'title': localizations.translate('approve_vacations')!,
        'subtitle': localizations.translate('approve_vacations_subtitle')!,
        'icon': Iconsax.airplane_square,
        'color': const Color(0xFF4A00E0),
        'onTap': () => _navigateTo(context, PendingVacationsScreen(user: widget.user)),
      },
      {
        'title': localizations.translate('approve_loans')!,
        'subtitle': localizations.translate('approve_loans_subtitle')!,
        'icon': Iconsax.money_recive,
        'color': const Color(0xFF009688),
        'onTap': () { /* No action yet */ },
      },
      // ### START: التعديل الرئيسي هنا ###
      {
        'title': localizations.translate('approve_permissions')!,
        'subtitle': localizations.translate('approve_permissions_subtitle')!,
        'icon': Iconsax.task_square,
        'color': const Color(0xFFE91E63),
        'onTap': () => _navigateTo(context, PendingPermissionsScreen(user: widget.user)),
      },
      // ### END: التعديل الرئيسي هنا ###
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final service = services[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildServiceItem(
                  context: context,
                  title: service['title'] as String,
                  subtitle: service['subtitle'] as String,
                  icon: service['icon'] as IconData,
                  color: service['color'] as Color,
                  onTap: service['onTap'] as VoidCallback,
                ),
              ),
            ),
          );
        },
        childCount: services.length,
      ),
    );
  }

  Widget _buildServiceItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shadowColor: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF333333))),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 15, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}