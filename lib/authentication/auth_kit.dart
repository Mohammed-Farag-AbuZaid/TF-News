// lib/authentication/auth_kit.dart
// Shared frame and input style for the sign-in / account screens.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/utils/constants/image_strings.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';

/// Calm Alabaster page with centred Crisp White sheet (no top bar, mobile-first).
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
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 540;
    return Scaffold(
      backgroundColor: tfCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              compact ? 14 : 20,
              compact ? 14 : 24,
              compact ? 14 : 20,
              compact ? 28 : 44,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  compact ? 20 : 28,
                  compact ? 22 : 28,
                  compact ? 20 : 28,
                  compact ? 24 : 30,
                ),
                decoration: BoxDecoration(
                  color: tfPaper,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: tfHair, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBack) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => Get.back(),
                          style: TextButton.styleFrom(
                            foregroundColor: tfAccent,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                          ),
                          icon: const Icon(Icons.chevron_left, size: 22),
                          label: const Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (showLogo)
                      const Image(
                        height: 42,
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
                    SizedBox(height: compact ? 18 : 24),
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Bricolage Grotesque',
                          color: tfInk,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          letterSpacing: -0.8,
                          fontSize: compact ? 25 : 30,
                        ),
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: tfMuted,
                          fontSize: compact ? 14 : 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                    SizedBox(height: compact ? 20 : 24),
                    child,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Recessed Stone input with hairline border and Fjord Slate focus ring.
InputDecoration authInput(String label, IconData icon, {Widget? suffix}) {
  OutlineInputBorder b(Color c, double w) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: tfMuted, fontSize: 14.5),
    floatingLabelStyle: const TextStyle(color: tfAccent),
    prefixIcon: Icon(icon, size: 20),
    suffixIcon: suffix,
    prefixIconColor: tfMuted,
    suffixIconColor: tfMuted,
    filled: true,
    fillColor: tfTile.withValues(alpha: 0.6),
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    border: b(tfHair, 1),
    enabledBorder: b(tfHair, 1),
    focusedBorder: b(tfAccent, 1.5),
    errorBorder: b(tfUrgent, 1),
    focusedErrorBorder: b(tfUrgent, 1.5),
    errorStyle: const TextStyle(color: tfUrgent, fontSize: 12),
  );
}