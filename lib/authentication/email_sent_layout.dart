// lib/authentication/email_sent_layout.dart
// Shared layout for the "we sent you an email" screens
// (ResetPassword and EmailVerification).
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/login_screen.dart';
import 'package:tf_news/utils/constants/image_strings.dart';
import 'package:tf_news/utils/constants/sizes.dart';
import 'package:tf_news/utils/helpers/helper_functions.dart';

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
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.clear),
            onPressed: () => Get.back(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image(
                image: const AssetImage(TImages.receiveEmail),
                width: THelperFunctions.screenWidth() * 0.6,
              ),
              const SizedBox(height: TSizes.spaceBwSections),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBwSections),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TSizes.spaceBwSections * 2),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.offAll(() => const LoginScreen()),
                  child: const Text("Done"),
                ),
              ),
              const SizedBox(height: TSizes.spaceBwItems),
              if (onResend != null)
                TextButton(
                  onPressed: onResend,
                  child: const Text("Resend Email"),
                ),
            ],
          ),
        ),
      ),
    );
  }
}