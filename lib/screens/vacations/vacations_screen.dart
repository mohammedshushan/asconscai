











import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/user_model.dart';
import '../../models/vacation_balance_model.dart';
import '../../services/vacation_service.dart';
import '../../widgets/vacation_balance_card.dart';
import '../../widgets/menu_list_item.dart';
import '../../app_localizations.dart';
import 'my_requests_screen.dart';
import 'new_request_screen.dart';
import '../../main.dart';

class VacationsScreen extends StatefulWidget {
  final UserModel user;

  const VacationsScreen({super.key, required this.user});

  @override
  State<VacationsScreen> createState() => _VacationsScreenState();
}

class _VacationsScreenState extends State<VacationsScreen> {
  late Future<List<VacationBalance>> _balanceFuture;
  final VacationService _vacationService = VacationService();
  List<VacationBalance> _currentBalances = []; // لحفظ الأرصدة الحالية

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _balanceFuture = _vacationService.getVacationBalance(widget.user.usersCode.toString());
    // حفظ نسخة من الأرصدة عند اكتمال التحميل
    _balanceFuture.then((balances) {
      if (mounted) {
        setState(() {
          _currentBalances = balances;
        });
      }
    });
  }

  void _refreshData() {
    setState(() {
      _loadData();
    });
  }

  void _navigateToMyRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyRequestsScreen(user: widget.user)),
    ).then((_) => _refreshData());
  }

  // --- تم تعديل هذه الدالة لتمرير الأرصدة ---
  void _navigateToNewRequest() async {
    final orders = await _vacationService.getVacationOrders(widget.user.usersCode.toString());
    final maxSerial = orders.map((o) => o.serialPyv).maxOrNull ?? 0;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewRequestScreen(
          user: widget.user,
          maxSerial: maxSerial,
          balances: _currentBalances, // **تمرير قائمة الأرصدة هنا**
        ),
      ),
    ).then((requestSubmitted) {
      if (requestSubmitted == true) {
        _refreshData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        color: const Color(0xFF6C63FF),
        child: FutureBuilder<List<VacationBalance>>(
          future: _balanceFuture,
          builder: (context, snapshot) {
            return CustomScrollView(
              slivers: [
                _buildModernAppBar(context, localizations),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))))
                else if (snapshot.hasError)
                  _buildErrorState(localizations, snapshot.error.toString())
                else if (!snapshot.hasData || snapshot.data!.isEmpty)
                    _buildEmptyState(localizations)
                  else
                    _buildContent(context, snapshot.data!, isRtl, localizations),
              ],
            );
          },
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
      shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(80),
          bottomRight: Radius.circular(80),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          localizations.translate('vacations') ?? 'Vacations',
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

  Widget _buildContent(BuildContext context, List<VacationBalance> balances, bool isRtl, AppLocalizations localizations) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.translate('vacation_balance_dashboard') ?? 'Balance Dashboard',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),

            AnimationLimiter(
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: balances.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  List<Color> colors = [const Color(0xFF9C27B0).withOpacity(.7), const Color(0xFF2196F3).withOpacity(.7)];
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: const Duration(milliseconds: 400),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: VacationBalanceCard(
                          c: colors[index % colors.length],
                          balance: balances[index],
                          isRtl: isRtl,
                          colorIndex: index,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            Text(
              localizations.translate('services') ?? 'Services',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            _buildServiceCards(context, localizations),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCards(BuildContext context, AppLocalizations localizations) {
    final List<Map<String, dynamic>> services = [
      {
        'title': localizations.translate('new_vacation_request') ?? 'New Request',
        'subtitle': localizations.translate('new_vacation_subtitle') ?? 'Submit a new time-off request',
        'icon': Icons.add_card_outlined,
        'color': const Color(0xFF6C63FF),
        'onTap': _navigateToNewRequest,
      },
      {
        'title': localizations.translate('my_requests') ?? 'My Requests',
        'subtitle': localizations.translate('my_requests_subtitle') ?? 'View your past and pending requests',
        'icon': Icons.list_alt_rounded,
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

  Widget _buildErrorState(AppLocalizations localizations, String error) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(localizations.translate('error_loading_data')!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
              child: Text(error, style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              localizations.translate('no_vacation_balance_found')!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}