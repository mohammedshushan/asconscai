import 'package:asconscai/models/permissions/permission_balance_model.dart';
import 'package:flutter/material.dart';


class PermissionBalanceCard extends StatelessWidget {
  final PermissionBalance balance;
  final bool isRtl;

  const PermissionBalanceCard({
    super.key,
    required this.balance,
    required this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            balance.type.getLocalizedName(isRtl),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF6C63FF),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceInfo("Total", balance.total),
              _buildBalanceInfo("Used", balance.consumed),
              _buildBalanceInfo("Left", balance.remaining),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}