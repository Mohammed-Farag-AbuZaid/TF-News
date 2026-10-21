// lib/authentication/email_sent_layout.dart
// Shared layout for the "we sent you an email" screens
// (ResetPassword and EmailVerification). No image, so no asset is needed.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/auth_kit.dart';
import 'package:tf_news/authentication/login_screen.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';

class EmailSentLayout extends StatelessWidget {
  const EmailSentLayout({
    super.key,
    required this.title,
    required this.message,
    required this.onResend,
  });

  final String title;
  final String message;
  final VoidCallback? onResend; // null hides the resend button

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      title: title,
      subtitle: message,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TfPrimaryButton(
            label: 'Done',
            expand: true,
            onPressed: () => Get.offAll(() => const LoginScreen()),
          ),
          if (onResend != null) ...[
            const SizedBox(height: 12),
            Center(
              child: TfTextAction(
                label: 'Resend email',
                onPressed: onResend,
              ),
            ),
          ],
        ],
      ),
    );
  }
}