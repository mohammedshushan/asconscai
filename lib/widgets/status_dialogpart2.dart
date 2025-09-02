import 'package:flutter/material.dart';

class StatusDialog {
  static void show(
      BuildContext context,
      String message, {
        required bool isSuccess,
        int duration = 3,
      }) {
    // إخفاء أي SnackBar قديم قبل إظهار واحد جديد
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    final SnackBar snackBar = SnackBar(
      content: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
      behavior: SnackBarBehavior.floating, // يجعلها طافية
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: duration),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}