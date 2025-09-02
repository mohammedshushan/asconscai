import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:page_transition/page_transition.dart';

// --- الألوان المستخرجة من الشعار ---
const Color kPrimaryColor = Color(0xFF1A335A); // الأزرق الداكن
const Color kAccentColor = Color(0xFFB71C1C); // الأحمر
const Color kBackgroundColor = Colors.white;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // دالة لتغيير اللغة في التطبيق
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar'); // اللغة الافتراضية هي العربية

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ascon Scai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryColor),
        scaffoldBackgroundColor: kBackgroundColor,
        useMaterial3: true,
        fontFamily: 'Cairo', // يمكنك استخدام خط مناسب للغتين
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      locale: _locale,
      supportedLocales: const [
        Locale('en', ''), // الإنجليزية
        Locale('ar', ''), // العربية
      ],
      // الشاشة الافتتاحية
      home: AnimatedSplashScreen(
        duration: 5000, // 5 ثواني
        splash: Hero(
          tag: 'logo',
          child: Image.asset('assets/images/logo.jpg'),
        )
            .animate()
            .scale(
          duration: 1500.ms,
          curve: Curves.easeInOut,
        )
            .fade(duration: 1500.ms),
        nextScreen: const LoginPage(),
        splashTransition: SplashTransition.fadeTransition,
        pageTransitionType: PageTransitionType.fade,
        backgroundColor: kBackgroundColor,
        splashIconSize: 250,
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  // --- دالة للحصول على النصوص حسب اللغة المختارة ---
  String getTranslatedString(String key) {
    Locale myLocale = Localizations.localeOf(context);
    Map<String, Map<String, String>> localizedValues = {
      'en': {
        'login_title': 'Login',
        'client_number': 'Client Number',
        'password': 'Password',
        'login_button': 'LOGIN',
      },
      'ar': {
        'login_title': 'تسجيل الدخول',
        'client_number': 'رقم العميل',
        'password': 'كلمة المرور',
        'login_button': 'دخــــول',
      },
    };
    return localizedValues[myLocale.languageCode]![key]!;
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        actions: [
          // --- زر تغيير اللغة ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextButton(
              onPressed: () {
                if (isArabic) {
                  MyApp.setLocale(context, const Locale('en'));
                } else {
                  MyApp.setLocale(context, const Locale('ar'));
                }
              },
              child: Text(
                isArabic ? 'EN' : 'عربي',
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Directionality(
        // تحديد اتجاه الصفحة بناءً على اللغة
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- الشعار مع حركة رائعة ---
                  Hero(
                    tag: 'logo',
                    child: Image.asset(
                      'assets/images/logo.jpg',
                      height: 150,
                    ),
                  )
                      .animate()
                      .slideY(
                      begin: -0.5,
                      duration: 900.ms,
                      curve: Curves.easeOutCubic)
                      .fadeIn(duration: 900.ms),
                  const SizedBox(height: 40),

                  // --- عنوان الصفحة ---
                  Text(
                    getTranslatedString('login_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 900.ms)
                      .shimmer(delay: 500.ms),
                  const SizedBox(height: 30),

                  // --- حقل رقم العميل ---
                  TextFormField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: getTranslatedString('client_number'),
                      prefixIcon: const Icon(Icons.person, color: kPrimaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال رقم العميل';
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 800.ms)
                      .slideX(
                      begin: isArabic ? 1.0 : -1.0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 20),

                  // --- حقل كلمة المرور ---
                  TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: getTranslatedString('password'),
                      prefixIcon: const Icon(Icons.lock, color: kPrimaryColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      return null;
                    },
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 800.ms)
                      .slideX(
                      begin: isArabic ? 1.0 : -1.0, curve: Curves.easeOutCubic),
                  const SizedBox(height: 40),

                  // --- زر تسجيل الدخول ---
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: kBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // منطق تسجيل الدخول يوضع هنا
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('جاري تسجيل الدخول...')),
                        );
                      }
                    },
                    child: Text(
                      getTranslatedString('login_button'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 900.ms, duration: 1000.ms)
                      .scale(
                      delay: 900.ms,
                      duration: 600.ms,
                      curve: Curves.elasticOut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}