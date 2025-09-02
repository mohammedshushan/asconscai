import 'package:flutter/material.dart';

class CurvedBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
   // final paint = Paint()..color = Color.fromRGBO(95, 14, 176,1);
    final paint = Paint()..color = Color.fromRGBO(95, 96, 185,1);

    // المسار العلوي (أصبح أصغر وأعلى بكثير)
    var path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height * 0.10); // يبدأ الانحناء من 10% فقط
    path.quadraticBezierTo(
        size.width / 2, size.height * 0.20, size.width, size.height * 0.18); // قمة المنحنى عند 20%
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);

    // المسار السفلي (أصبح أصغر وأسفل بكثير)
    var bottomPath = Path();
    bottomPath.moveTo(0, size.height);
    bottomPath.lineTo(0, size.height * 0.92); // يبدأ الانحناء من 92%
    bottomPath.quadraticBezierTo(
        size.width / 2, size.height * 0.90, size.width, size.height * 0.95); // قمة المنحنى السفلي عند 84%
    bottomPath.lineTo(size.width, size.height);
    bottomPath.close();
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}