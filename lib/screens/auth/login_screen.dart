
import 'dart:ui'; // لاستخدام BackdropFilter
import 'package:asconscai/curved_background_painter.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app_localizations.dart';

import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  const LoginScreen({super.key, required this.onLanguageChanged});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _userCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _userCodeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    final localizations = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.login(
        _userCodeController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      // تأكد من إغلاق أي dialogs مفتوحة قبل عرض الجديد
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);

      await _showCustomDialog(
        message: localizations.translate('loginSuccess'),
        isSuccess: true,
      );

      if (!mounted) return;

      // استخدام pushAndRemoveUntil مع التأكد من إزالة كل الـ routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
            (Route<dynamic> route) => false,
      );

    } catch (e) {
      if (!mounted) return;

      final errorString = e.toString().replaceAll('Exception: ', '');
      final errorMessage = localizations.translate(errorString);

      setState(() => _isLoading = false);

      // تأكد من أن الـ context صحيح قبل عرض الـ dialog
      if (mounted) {
        await _showCustomDialog(
          message: errorMessage,
          isSuccess: false,
        );
      }
    }
  }
  Future<void> _showCustomDialog({
    required String message,
    required bool isSuccess,
  }) async {
    if (!mounted) return;

    final localizations = AppLocalizations.of(context)!;

    // التأكد من عدم وجود dialogs أخرى مفتوحة
    while (Navigator.of(context).canPop() && ModalRoute.of(context)?.isActive != true) {
      Navigator.of(context).pop();
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      useRootNavigator: true, // مهم جداً لتجنب التضارب
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSuccess
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.of(dialogContext, rootNavigator: true).pop();
                        },
                        child: Text(
                          localizations.translate('continueButton'),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


  // إضافة دالة لإعادة تعيين حالة الشاشة عند العودة إليها
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resetScreenState();
    });
  }

  void _resetScreenState() {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      // عدم مسح النصوص لتسهيل إعادة المحاولة للمستخدم
      // _userCodeController.clear();
      // _passwordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final currentLocale = Localizations.localeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomPaint(
            painter: CurvedBackgroundPainter(),
            child: Container(height: size.height),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildLanguageSwitcher(currentLocale),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: size.height * 0.02),
                            Hero(
                              tag: 'user_avatar',
                              child: _buildLogo(),
                            ),
                            const SizedBox(height: 16),
                            _buildTitles(localizations),
                            const SizedBox(height: 30),
                            _buildLoginForm(localizations),
                            const SizedBox(height: 20),
                            _buildLoginButton(localizations),
                            const SizedBox(height: 15),
                            _buildSocialButtons(),
                            const SizedBox(height: 15),
                            _buildRegisterNow(localizations),
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(AppLocalizations localizations) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _performLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(95, 96, 185,1),
          disabledBackgroundColor: const Color.fromRGBO(95, 96, 185,1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: _isLoading ? 0 : 2,
        ),
        child: _isLoading
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Text(
          localizations.translate('login'),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(AppLocalizations localizations) {
    return Column(
      children: [
        TextFormField(
          controller: _userCodeController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.black87),
          textDirection: TextDirection.ltr,
          enabled: !_isLoading, // تعطيل الحقول أثناء التحميل
          decoration: _inputDecoration(
            hint: localizations.translate('userCodeHint'),
            icon: Icons.supervised_user_circle_rounded,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.translate('userCodeValidationError');
            }
            if (int.tryParse(value) == null) {
              return localizations.translate('userCodeMustBeNumber');
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _passwordController,
          style: const TextStyle(color: Colors.black87),
          obscureText: _obscurePassword,
          textDirection: TextDirection.ltr,
          enabled: !_isLoading, // تعطيل الحقول أثناء التحميل
          decoration: _inputDecoration(
            hint: localizations.translate('passwordHint'),
            icon: Icons.lock,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: _isLoading ? Colors.grey.shade300 : Colors.grey,
              ),
              onPressed: _isLoading ? null : () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return localizations.translate('passwordValidationError');
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLanguageSwitcher(Locale currentLocale) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: GestureDetector(
          onTap: _isLoading ? null : () {
            final newLocale = currentLocale.languageCode == 'en'
                ? const Locale('ar', '')
                : const Locale('en', '');
            widget.onLanguageChanged(newLocale);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE7E6E8).withOpacity(_isLoading ? 0.05 : 0.1),
                  const Color(0xFFE7E6E8).withOpacity(_isLoading ? 0.02 : 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: const Color(0xFFFFFFFF).withOpacity(_isLoading ? 0.1 : 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language,
                  color: Color(0xFFE7E6E8).withOpacity(_isLoading ? 0.5 : 1.0),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  currentLocale.languageCode == 'en' ? 'AR' : 'EN',
                  style: TextStyle(
                    color: Color(0xFFE7E6E8).withOpacity(_isLoading ? 0.5 : 1.0),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      height: 110,
      width: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(95, 96, 185,1).withOpacity(_isLoading ? 0.3 : 1.0),
            spreadRadius: 2,
            blurRadius: 15,
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundImage: const AssetImage('assets/newlogo.png'),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildTitles(AppLocalizations localizations) {
    return Column(
      children: [
        Text(
          localizations.translate('systemTitle'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87.withOpacity(_isLoading ? 0.7 : 1.0),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: Colors.blueAccent.withOpacity(_isLoading ? 0.2 : 0.3),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localizations.translate('signInToYourAccount'),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 18,
            color: Colors.grey[600]?.withOpacity(_isLoading ? 0.7 : 1.0),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            Icons.facebook,
            color: Color(0xFF1877F2).withOpacity(_isLoading ? 0.5 : 1.0),
            size: 28,
          ),
          onPressed: _isLoading ? null : () {},
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.public,
            color: Colors.black.withOpacity(_isLoading ? 0.3 : 1.0),
            size: 28,
          ),
          onPressed: _isLoading ? null : () {},
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.play_arrow,
            color: Colors.red.withOpacity(_isLoading ? 0.5 : 1.0),
            size: 28,
          ),
          onPressed: _isLoading ? null : () {},
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.work,
            color: Colors.blueAccent.withOpacity(_isLoading ? 0.5 : 1.0),
            size: 28,
          ),
          onPressed: _isLoading ? null : () {},
        ),
      ],
    );
  }

  Widget _buildRegisterNow(AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          localizations.translate('dontHaveAccount'),
          style: GoogleFonts.poppins(
            color: Colors.black.withOpacity(_isLoading ? 0.5 : 0.9),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: _isLoading ? null : () {},
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            localizations.translate('registerNow'),
            style: GoogleFonts.poppins(
              color: Colors.black.withOpacity(_isLoading ? 0.5 : 1.0),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0, top: 10.0),
      child: Text(
        'Ascon SCAi © 2025',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: Colors.white.withOpacity(_isLoading ? 0.7 : 1.0),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,

      hintStyle: TextStyle(
        color: _isLoading ? Colors.black26 : Colors.black38,
      ),
      prefixIcon: Icon(
        icon,
        color: _isLoading ? Colors.grey.shade300 : Colors.grey,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: _isLoading ? Colors.grey.shade300 : Colors.grey,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade300, width: 2),
      ),
      errorStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      filled: true,
      fillColor: _isLoading ? Colors.grey.shade50 : Colors.white,
    );
  }
}