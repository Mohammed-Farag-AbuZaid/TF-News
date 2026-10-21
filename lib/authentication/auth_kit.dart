// lib/authentication/auth_kit.dart
// Shared frame and input style for the sign-in / account screens.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/utils/constants/image_strings.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';

/// White page, narrow centred column: brand or logo, big title, message, content.
class AuthFrame extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final bool showLogo;

  const AuthFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack = false,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBack)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          foregroundColor: tfAccent,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 44),
                        ),
                        icon: const Icon(Icons.chevron_left, size: 24),
                        label: const Text('Back',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w500)),
                      ),
                    )
                  else
                    const SizedBox(height: 44),
                  const SizedBox(height: 16),
                  if (showLogo)
                    const Image(
                      height: 56,
                      alignment: Alignment.centerLeft,
                      image: AssetImage(TImages.tfLogo),
                    )
                  else
                    const Text(
                      'TF News',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tfInk,
                        letterSpacing: -0.2,
                      ),
                    ),
                  const SizedBox(height: 40),
                  Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: tfInk,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                        letterSpacing: -1,
                        fontSize: 34,
                      ),
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(subtitle!,
                        style: const TextStyle(
                            color: tfMuted, fontSize: 16, height: 1.5)),
                  ],
                  const SizedBox(height: 32),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey filled input with no border until focused.
InputDecoration authInput(String label, IconData icon, {Widget? suffix}) {
  OutlineInputBorder b(Color? c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: c == null ? BorderSide.none : BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: tfMuted, fontSize: 15),
    floatingLabelStyle: const TextStyle(color: tfMuted),
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffix,
    prefixIconColor: tfMuted,
    suffixIconColor: tfMuted,
    filled: true,
    fillColor: tfTile,
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
    border: b(null, 0),
    enabledBorder: b(null, 0),
    focusedBorder: b(tfAccent, 1.5),
    errorBorder: b(tfUrgent, 1),
    focusedErrorBorder: b(tfUrgent, 1.5),
    errorStyle: const TextStyle(color: tfUrgent, fontSize: 12),
  );
}