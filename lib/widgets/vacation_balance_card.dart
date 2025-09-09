











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