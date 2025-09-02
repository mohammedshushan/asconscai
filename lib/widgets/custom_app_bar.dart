import 'package:flutter/material.dart';
import '../app_localizations.dart';
import '../main.dart'; // لاستدعاء دالة تغيير اللغة

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold,color: Colors.white)),
      backgroundColor: const Color(0xFF6C63FF),
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        onPressed: () => Navigator.of(context).pop(),
      )
          : null,
      actions: [
        // زر تغيير اللغة
        IconButton(
          icon: const Icon(Icons.language_outlined, size: 26,color: Colors.white),
          onPressed: () {
            final currentLocale = Localizations.localeOf(context);
            final newLocale = currentLocale.languageCode == 'en'
                ? const Locale('ar', '')
                : const Locale('en', '');
            // نفترض أن هذه الدالة موجودة في MyApp لتغيير اللغة
            MyApp.of(context)?.changeLanguage(newLocale);
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
