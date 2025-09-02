import 'package:flutter/material.dart';

// لجعل الـ Widget يعمل كـ AppBar، يجب أن يستخدم PreferredSizeWidget
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions; // لإضافة أي أزرار إضافية مثل زر تغيير اللغة

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // لون الخلفية ليتناسب مع هوية التطبيق
      backgroundColor: Colors.white,
      // لون أيقونة الرجوع والنصوص
      foregroundColor: Colors.black87,
      elevation: 1, // ظل خفيف للفصل عن محتوى الصفحة
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white
        ),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  // يجب تحديد الحجم المفضل للـ AppBar
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}