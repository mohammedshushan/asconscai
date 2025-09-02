import 'package:asconscai/app_localizations.dart';
import 'package:asconscai/models/permissions/permission_balance_model.dart';
import 'package:asconscai/models/user_model.dart';
import 'package:asconscai/screens/permissions/my_permissions_screen.dart';
import 'package:asconscai/screens/permissions/new_permission_screen.dart';
import 'package:asconscai/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../main.dart';

class PermissionsScreen extends StatefulWidget {
  final UserModel user;
  const PermissionsScreen({super.key, required this.user});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with TickerProviderStateMixin {
  late Future<List<PermissionBalance>> _balanceFuture;
  final PermissionService _permissionService = PermissionService();
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  void _loadData() {
    setState(() {
      _balanceFuture = _fetchBalances();
    });
    _cardAnimationController.reset();
    _cardAnimationController.forward();
  }

  Future<List<PermissionBalance>> _fetchBalances() async {
    final types = await _permissionService.getPermissionTypes();
    return types.map((type) {
      return PermissionBalance(
        type: type,
        total: 8,
        consumed: 3,
        remaining: 5,
      );
    }).toList();
  }

  void _navigateToMyRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyPermissionsScreen(user: widget.user)),
    ).then((_) => _loadData());
  }

  void _navigateToNewRequest() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewPermissionScreen(user: widget.user),
      ),
    ).then((requestSubmitted) {
      if (requestSubmitted == true) {
        _loadData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: const Color(0xFF6C63FF),
        child: FutureBuilder<List<PermissionBalance>>(
          future: _balanceFuture,
          builder: (context, snapshot) {
            return CustomScrollView(
              slivers: [
                _buildModernAppBar(context, localizations),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                      child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6C63FF))))
                else if (snapshot.hasError)
                  SliverFillRemaining(
                      child: Center(child: Text(snapshot.error.toString())))
                else if (!snapshot.hasData || snapshot.data!.isEmpty)
                    SliverFillRemaining(
                        child: Center(
                            child: Text(localizations.translate('no_data_found') ??
                                'No Data Found')))
                  else
                    _buildContentSliver(
                        context, snapshot.data!, localizations),
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
          localizations.translate('permissions') ?? 'Permissions',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language_outlined, color: Colors.white, size: 26),
          onPressed: () {
            final currentLocale = Localizations.localeOf(context);
            final newLocale = currentLocale.languageCode == 'en'
                ? const Locale('ar', '')
                : const Locale('en', '');
            MyApp.of(context)?.changeLanguage(newLocale);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildContentSliver(BuildContext context, List<PermissionBalance> balances,
      AppLocalizations localizations) {
    final isRtl =
    Bidi.isRtlLanguage(Localizations.localeOf(context).languageCode);

    return SliverToBoxAdapter(
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value.clamp(0.0, 1.0),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.translate('permissions_balance') ??
                          'رصيد الأذونات',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _cardAnimationController,
                      builder: (context, child) {
                        final animation = Tween<double>(
                          begin: 0.0,
                          end: 1.0,
                        ).animate(CurvedAnimation(
                          parent: _cardAnimationController,
                          curve: Curves.elasticOut,
                        ));

                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - animation.value)),
                          child: Transform.scale(
                            scale: 0.9 + (0.1 * animation.value),
                            child: Opacity(
                              opacity: animation.value.clamp(0.0, 1.0),
                              child:
                              _buildBalanceCardsContainer(balances, isRtl),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text(
                      localizations.translate('services') ?? 'الخدمات',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildAnimatedServiceCard(
                      title:
                      localizations.translate('new_permission_request')!,
                      subtitle:
                      localizations.translate('new_permission_subtitle')!,
                      icon: Icons.add_box_rounded,
                      color: const Color(0xFF6C63FF),
                      onTap: _navigateToNewRequest,
                      delay: 0.0,
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedServiceCard(
                      title:
                      localizations.translate('my_permission_requests')!,
                      subtitle:
                      localizations.translate('my_permission_subtitle')!,
                      icon: Icons.history_rounded,
                      color: const Color(0xFF4CAF50),
                      onTap: _navigateToMyRequests,
                      delay: 0.2,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCardsContainer(List<PermissionBalance> balances, bool isRtl) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6C63FF).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: balances.asMap().entries.map((entry) {
          final index = entry.key;
          final balance = entry.value;

          return Expanded(
            child: AnimatedBuilder(
              animation: _cardAnimationController,
              builder: (context, child) {
                final delay = index * 0.1;
                final itemAnimation = Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: _cardAnimationController,
                  curve: Interval(delay, 1.0, curve: Curves.easeOut),
                ));

                return Transform.translate(
                  offset: Offset(0, 15 * (1 - itemAnimation.value)),
                  child: Opacity(
                    opacity: itemAnimation.value.clamp(0.0, 1.0),
                    child: _buildSingleBalanceCard(balance, isRtl, index, balances.length),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSingleBalanceCard(PermissionBalance balance, bool isRtl, int index, int totalLength) {
    Color cardColor;
    IconData cardIcon;

    if ((balance.type.reasonEn ?? "").toLowerCase().contains('permission') ||
        balance.type.reasonAr.contains('اذن')) {
      cardColor = const Color(0xFFE91E63);
      cardIcon = Icons.event_available;
    } else if ((balance.type.reasonEn ?? "").toLowerCase().contains('business') ||
        balance.type.reasonAr.contains('مأمورية')) {
      cardColor = const Color(0xFF26C6DA);
      cardIcon = Icons.business_center;
    } else {
      cardColor = const Color(0xFF6C63FF);
      cardIcon = Icons.assignment;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: cardColor.withOpacity(0.3),
                width: 1.2,
              ),
            ),
            child: Icon(
              cardIcon,
              color: cardColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            balance.remaining.toString(),
            style: TextStyle(
              color: cardColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'متبقي',
            style: TextStyle(
              color: cardColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 25,
            height: 1,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      balance.consumed.toString(),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'مستخدم',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 18,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      balance.total.toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الإجمالي',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              isRtl ? balance.type.reasonAr : (balance.type.reasonEn ?? balance.type.reasonAr),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cardColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ############# START OF FIX #############
  Widget _buildAnimatedServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final cardAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay + 0.4, 1.0, curve: Curves.elasticOut),
        ));

        final slideAnimation = Tween<double>(
          begin: 30.0,
          end: 0.0,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Interval(delay + 0.4, 1.0, curve: Curves.easeOut),
        ));

        // This is the FIX: ensuring opacity is always between 0.0 and 1.0
        final opacity = cardAnimation.value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, slideAnimation.value),
          child: Opacity(
            opacity: opacity, // Use the clamped value here
            child: _buildServiceCard(
              title: title,
              subtitle: subtitle,
              icon: icon,
              color: color,
              onTap: onTap,
            ),
          ),
        );
      },
    );
  }
  // ############# END OF FIX #############

  Widget _buildServiceCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Hero(
                tag: 'service_icon_${icon.codePoint}',
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}