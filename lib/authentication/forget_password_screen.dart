// lib/authentication/forget_password_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/auth_kit.dart';
import 'package:tf_news/authentication/forget_password_controller.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:tf_news/utils/validators/validation.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    return AuthFrame(
      showBack: true,
      title: 'Reset your password',
      subtitle: "Enter your email and we'll send you a link to set a new one.",
      child: Form(
        key: controller.forgetPasswordFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller.email,
              keyboardType: TextInputType.emailAddress,
              validator: TValidator.validateEmail,
              onFieldSubmitted: (_) => controller.sendPasswordResetEmail(),
              decoration: authInput('Email', Icons.mail_outline),
            ),
            const SizedBox(height: 24),
            TfPrimaryButton(
              label: 'Send reset link',
              expand: true,
              onPressed: () => controller.sendPasswordResetEmail(),
            ),
          ],
        ),
      ),
    );
  }
}