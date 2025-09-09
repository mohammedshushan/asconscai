import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/user_model.dart';
import '../../services/loan_service.dart';
import '../../widgets/info_dialog.dart'; // تمت الإضافة لعرض رسائل الخطأ
import '../../app_localizations.dart';
import 'my_loan_requests_screen.dart';
import '../loan/new_loan_request_screen.dart';
import '../../main.dart';

class LoansScreen extends StatefulWidget {
  final UserModel user;
  const LoansScreen({super.key, required this.user});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final LoanService _loanService = LoanService();

  void _navigateToMyRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyLoanRequestsScreen(user: widget.user)),
    );
  }

  // -->> ✅ بداية الجزء الذي تم تعديله بالكامل <<--
  void _navigateToNewRequest() async {
    final localizations = AppLocalizations.of(context)!;

    // إظهار مؤشر تحميل للمستخدم
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)));
      },
    );

    try {
      final requests = await _loanService.getLoanRequests(widget.user.usersCode.toString());
      final maxSerial = requests.map((r) => r.reqSerial).maxOrNull ?? 0;

      if (!mounted) return;
      Navigator.pop(context); // إغلاق مؤشر التحميل

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NewLoanRequestScreen(user: widget.user, maxSerial: maxSerial)),
      );
    } catch (e) {
      // طباعة الخطأ الفعلي في الكونسول للمطور
      print("Error fetching loan requests before navigation: $e");

      if (!mounted) return;
      Navigator.pop(context); // إغلاق مؤشر التحميل في حالة الخطأ

      // عرض رسالة خطأ آمنة للمستخدم
      showDialog(
        context: context,
        builder: (_) => InfoDialog(
          title: localizations.translate('error')!,
          message: localizations.translate('failed_to_load_data') ?? 'Failed to load necessary data. Please try again.',
          isSuccess: false,
        ),
      );
    }
  }
  // -->> 🔚 نهاية الجزء الذي تم تعديله <<--


  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(context, localizations),
          _buildContent(context, isRtl, localizations),
        ],
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
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(80),
          bottomRight: Radius.circular(80),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          localizations.translate('loan_management') ?? 'Loan Management',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
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

  Widget _buildContent(BuildContext context, bool isRtl, AppLocalizations localizations) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dashboard Section
            Text(
              localizations.translate('loan_balance_dashboard') ?? 'Loan Balance Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildLoanBalanceCards(context, isRtl, localizations),
            const SizedBox(height: 32),

            // Services Section
            Text(
              localizations.translate('services') ?? 'Services',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            _buildServiceCards(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanBalanceCards(BuildContext context, bool isRtl, AppLocalizations localizations) {
    final List<Map<String, dynamic>> loanData = [
      {
        'title': localizations.translate('personal_reasons') ?? 'Personal Reasons',
        'totalBalance': 10,
        'used': 5,
        'remaining': 5,
        'color': const Color(0xFF9C27B0).withOpacity(.7),

      },
      {
        'title': localizations.translate('employee_deductions') ?? 'Employee Deductions',
        'totalBalance': 20,
        'used': 16,
        'remaining': 4,
        'color': const Color(0xFF2196F3).withOpacity(.7),

      },
    ];

    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: loanData.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 400),
            columnCount: 2,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _buildLoanBalanceCard(loanData[index], isRtl),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoanBalanceCard(Map<String, dynamic> data, bool isRtl) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            data['color'],
            data['color'].withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: data['color'].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    data['title'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),

              ],
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceRow(!isRtl?'Total':"الاجمالي", data['totalBalance'].toString(), Colors.white.withOpacity(0.8)),
                const SizedBox(height: 4),
                _buildBalanceRow(!isRtl?'Used':"المستخدم", data['used'].toString(), Colors.white.withOpacity(0.8)),
                const SizedBox(height: 4),
                _buildBalanceRow(!isRtl?'Remaining':"المتبقي", data['remaining'].toString(), Colors.white,fontwqight: FontWeight.bold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(String label, String value, Color color,{FontWeight fontwqight= FontWeight.w500}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: fontwqight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCards(BuildContext context, AppLocalizations localizations) {
    final List<Map<String, dynamic>> services = [
      {
        'title': localizations.translate('new_loan_request') ?? 'New Loan Request',
        'subtitle': localizations.translate('new_loan_subtitle') ?? 'Apply for a new financial loan',
        'icon': Icons.post_add_rounded,
        'color': const Color(0xFF6C63FF),
        'onTap': _navigateToNewRequest,
      },
      {
        'title': localizations.translate('my_loan_requests') ?? 'My Requests',
        'subtitle': localizations.translate('my_loan_subtitle') ?? 'Track your loan application status',
        'icon': Icons.receipt_long_rounded,
        'color': const Color(0xFF4CAF50),
        'onTap': _navigateToMyRequests,
      },
    ];

    return AnimationLimiter(
      child: Column(
        children: services.asMap().entries.map((entry) {
          final index = entry.key;
          final service = entry.value;

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 500),
            child: SlideAnimation(
              horizontalOffset: 50.0,
              child: FadeInAnimation(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: service['onTap'],
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: service['color'].withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: service['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                service['icon'],
                                color: service['color'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['title'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service['subtitle'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: service['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: service['color'],
                                size: 16,
                              ),
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
        }).toList(),
      ),
    );
  }
}