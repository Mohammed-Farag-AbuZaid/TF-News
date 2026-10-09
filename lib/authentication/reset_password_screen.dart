// lib/authentication/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/email_sent_layout.dart';
import 'package:tf_news/authentication/forget_password_controller.dart';

class ResetPassword extends StatelessWidget {
  const ResetPassword({super.key, this.title, this.message, this.email});

  final String? title;
  final String? message;
  final String? email;

  @override
  Widget build(BuildContext context) {
    return EmailSentLayout(
      title: title ?? 'Password Reset Email Sent',
      message: message ??
          'your Account Security is our top priority. We have sent you an email to $email with instructions to reset your password.',
      onResend: email == null
          ? null
          : () => Get.find<ForgetPasswordController>()
              .resendPasswordResetEmail(email!),
    );
  }
}