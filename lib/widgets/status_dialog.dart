// lib/widgets/status_dialog.dart

import 'package:flutter/material.dart';

class StatusDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final String? buttonText; // نص الزر قابل للتخصيص

  const StatusDialog({
    super.key,
    required this.title,
    required this.message,
    this.isSuccess = true,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = isSuccess ? Colors.green.shade600 : Colors.red.shade600;
    final backgroundColor = isSuccess ? Colors.green.shade50 : Colors.red.shade50;
    final icon = isSuccess ? Icons.check_circle_outline_rounded : Icons.highlight_off_rounded;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: themeColor, size: 50),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                buttonText ?? (isSuccess ? 'موافق' : 'إغلاق'),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}