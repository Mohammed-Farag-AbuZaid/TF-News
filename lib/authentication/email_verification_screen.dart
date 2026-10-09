// lib/authentication/email_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/authentication_repository.dart';
import 'package:tf_news/authentication/email_sent_layout.dart';
import 'package:tf_news/authentication/email_verification_controller.dart';

class EmailVerification extends StatelessWidget {
  const EmailVerification({super.key, this.title, this.message});

  final String? title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(EmailVerificationController());
    final userEmail = AuthenticationRepository.instance.authUser?.email ?? '';

    return EmailSentLayout(
      title: title ?? 'Verification Email Sent',
      message: message ??
          'your Account Security is our top priority. We have sent you an email with instructions to verify your email address.',
      onResend: () => controller.resendEmailVerificationEmail(userEmail),
    );
  }
}