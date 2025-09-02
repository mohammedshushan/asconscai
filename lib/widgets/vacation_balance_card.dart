/*
import 'package:flutter/material.dart';
import '../models/vacation_balance_model.dart';
import '../app_localizations.dart';

class VacationBalanceCard extends StatelessWidget {
  final VacationBalance balance;
  final bool isRtl;
  final int colorIndex;

  const VacationBalanceCard({
    super.key,
    required this.balance,
    required this.isRtl,
    required this.colorIndex,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final vacationName = isRtl ? balance.vcncDescA : balance.vcncDescE;

    final List<Color> baseColors = [
      const Color(0xFF6C63FF),
      const Color(0xFF3F51B5),
      const Color(0xFF009688),
      const Color(0xFF4CAF50),
      const Color(0xFFF44336),
      const Color(0xFFE91E63),
    ];
    final color = baseColors[colorIndex % baseColors.length];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border(top: BorderSide(color: color, width: 5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(
            vacationName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildBalanceRow(context, localizations.translate('total_balance')!, balance.fullBalance.toStringAsFixed(1), Colors.black87),
              _buildBalanceRow(context, localizations.translate('used')!, balance.total.toStringAsFixed(1), Colors.orange.shade800),
              _buildBalanceRow(context, localizations.translate('remaining')!, balance.remainBal.toStringAsFixed(1), Colors.green.shade800, isBold: true),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBalanceRow(BuildContext context, String title, String value, Color valueColor, {bool isBold = false}) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            '$value ${localizations.translate('days')}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}*/

/*
import 'package:flutter/material.dart';
import '../models/vacation_balance_model.dart';
import '../app_localizations.dart';

class VacationBalanceCard extends StatefulWidget {
  final VacationBalance balance;
  final bool isRtl;
  final int colorIndex;

  const VacationBalanceCard({
    super.key,
    required this.balance,
    required this.isRtl,
    required this.colorIndex,
  });

  @override
  State<VacationBalanceCard> createState() => _VacationBalanceCardState();
}

class _VacationBalanceCardState extends State<VacationBalanceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600 + (widget.colorIndex * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final vacationName = widget.isRtl ? widget.balance.vcncDescA : widget.balance.vcncDescE;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth < 400;

    final List<List<Color>> gradientColors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFF30cfd0), const Color(0xFFa8edea)],
    ];

    final gradientPair = gradientColors[widget.colorIndex % gradientColors.length];

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                height: isSmallScreen ? 180 : isMediumScreen ? 190 : 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientPair,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: gradientPair[0].withOpacity(0.3),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with icon and title
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.card_travel_rounded,
                                color: Colors.white,
                                size: isSmallScreen ? 20 : 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                vacationName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.2),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isSmallScreen ? 8 : 12),

                        // Balance information
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildBalanceRow(
                                context,
                                localizations.translate('total_balance')!,
                                widget.balance.fullBalance.toStringAsFixed(1),
                                Colors.white.withOpacity(0.9),
                                isSmallScreen: isSmallScreen,
                              ),
                              _buildBalanceRow(
                                context,
                                localizations.translate('used')!,
                                widget.balance.total.toStringAsFixed(1),
                                Colors.orange.shade200,
                                isSmallScreen: isSmallScreen,
                              ),
                              _buildBalanceRow(
                                context,
                                localizations.translate('remaining')!,
                                widget.balance.remainBal.toStringAsFixed(1),
                                Colors.green.shade200,
                                isBold: true,
                                isSmallScreen: isSmallScreen,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceRow(
      BuildContext context,
      String title,
      String value,
      Color valueColor, {
        bool isBold = false,
        required bool isSmallScreen,
      }) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 3,
            child: Text(
              title,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            flex: 2,
            child: Text(
              '$value ${localizations.translate('days')}',
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor,
                shadows: [
                  Shadow(
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                    color: Colors.black.withOpacity(0.2),
                  ),
                ],
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
*/
















import 'package:flutter/material.dart';
import 'dart:math';
import '../models/vacation_balance_model.dart';
import '../app_localizations.dart';

class VacationBalanceCard extends StatelessWidget {
  final VacationBalance balance;
  final bool isRtl;
  final int colorIndex;
  final Color c;

  const VacationBalanceCard({
    super.key,
    required this.balance,
    required this.isRtl,
    required this.colorIndex,
    required this.c
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final vacationName = isRtl ? balance.vcncDescA : balance.vcncDescE;

    final List<List<Color>> gradientColors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)], // Purple
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)], // Blue
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)], // Green
      [const Color(0xFFfa709a), const Color(0xFFfee140)], // Pink/Yellow
      [const Color(0xFFf093fb), const Color(0xFFf5576c)], // Magenta/Red
      [const Color(0xFF30cfd0), const Color(0xFFa8edea)], // Teal
    ];

    final gradientPair = gradientColors[colorIndex % gradientColors.length];

    return Container(
      decoration: BoxDecoration(
        color: this.c,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientPair[0].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Transform.rotate(
              angle: -pi / 4,
              child: Icon(
                Icons.beach_access,
                size: 80,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
             // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  vacationName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                    shadows: [Shadow(offset: Offset(0, 1), blurRadius: 2, color: Colors.black26)],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [//total_balance
                      _buildBalanceRow(context, localizations.translate('total_balance')!, balance.fullBalance.toStringAsFixed(0), Colors.white70,isBold: true),
                      _buildBalanceRow(context, localizations.translate('used')!, balance.total.toStringAsFixed(0), Colors.white70),
                      _buildBalanceRow(context, localizations.translate('remaining')!, balance.remainBal.toStringAsFixed(0), Colors.white, isBold: true),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: balance.fullBalance > 0 ? balance.remainBal / balance.fullBalance : 0,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // تم تعديل هذه الدالة لحل مشكلة التداخل
  Widget _buildBalanceRow(BuildContext context, String title, String value, Color valueColor, {bool isBold = false}) {
    final localizations = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
          ),
          const SizedBox(width: 8),
          // استخدام Flexible و FittedBox لجعل النص يتأقلم مع المساحة
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '$value ${localizations.translate('days')}',
                style: TextStyle(
                  fontSize: isBold ? 16 : 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}