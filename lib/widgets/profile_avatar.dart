import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileAvatar extends StatefulWidget {
  final String imageUrl;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 28, // حجم افتراضي مناسب للـ AppBar
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  Future<bool>? _imageCheckFuture;

  @override
  void initState() {
    super.initState();
    _imageCheckFuture = _checkIfImageExists();
  }

  @override
  void didUpdateWidget(covariant ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إذا تغير الرابط (مثلاً عند تحديث الصورة)، نعيد الفحص
    if (widget.imageUrl != oldWidget.imageUrl) {
      setState(() {
        _imageCheckFuture = _checkIfImageExists();
      });
    }
  }

  // الدالة الأساسية للحل: تفحص الرابط أولاً
  Future<bool> _checkIfImageExists() async {
    try {
      // نستخدم طلب HEAD لأنه أسرع، فهو يجلب الـ headers فقط دون تحميل الصورة كاملة
      final response = await http.head(Uri.parse(widget.imageUrl));
      // إذا كان الـ status code ناجحًا (في نطاق 200)، فـ الصورة موجودة
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      // أي خطأ يعني أن الصورة غير موجودة أو لا يمكن الوصول إليها
      print("Image check failed: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _imageCheckFuture,
      builder: (context, snapshot) {
        // حالة التحقق من وجود الصورة
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey.shade200,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }

        // إذا كانت الصورة موجودة (true)، نعرضها
        if (snapshot.hasData && snapshot.data == true) {
          return CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey.shade200, // خلفية أثناء التحميل
            backgroundImage: NetworkImage(widget.imageUrl),
          );
        }

        // إذا كانت الصورة غير موجودة (false) أو حدث خطأ، نعرض الأيقونة الافتراضية
        return CircleAvatar(
          radius: widget.radius,
          backgroundColor: Colors.grey.shade200,
          child: Icon(
            Icons.person,
            size: widget.radius,
            color: Colors.grey.shade400,
          ),
        );
      },
    );
  }
}