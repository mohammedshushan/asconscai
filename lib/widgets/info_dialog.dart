import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class InfoDialog extends StatelessWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final String? buttonText;

  const InfoDialog({
    super.key,
    required this.title,
    required this.message,
    this.isSuccess = true,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final lottieAsset = isSuccess ? 'assets/animations/success.json' : 'assets/animations/error.json';

    return PopScope(
      canPop: true,
      child: Material(
        color: Colors.transparent,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            child: AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              backgroundColor: Colors.white,
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Lottie.asset(
                      lottieAsset,
                      repeat: false,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          size: 80,
                          color: isSuccess ? Colors.green : Colors.red,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C63FF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 2,
                      ),
                      child: Text(
                        buttonText ?? 'موافق',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}