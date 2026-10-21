// lib/authentication/change_academic_info_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/auth_kit.dart';
import 'package:tf_news/authentication/login_screen.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:url_launcher/url_launcher.dart';

class ChangeAcademicInfo extends StatelessWidget {
  const ChangeAcademicInfo({
    super.key,
    this.showBackArrow = true,
    this.fullMessage = true,
    this.title = 'Change Academic Info',
    this.description =
        'This action cannot be done from here, you can change your Academic Info from the TF-Unions website',
  });

  final String title;
  final String description;
  final bool fullMessage;
  final bool showBackArrow;

  @override
  Widget build(BuildContext context) {
    return AuthFrame(
      showBack: showBackArrow,
      title: title,
      subtitle: fullMessage
          ? 'This action cannot be done from here. You can change your $description and all other Academic Info from the TF-Unions website.'
          : description,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TfPrimaryButton(
            label: 'Visit TF-Unions',
            icon: Icons.open_in_new,
            expand: true,
            onPressed: () => launchUrl(
              Uri.parse('https://tfunions.vercel.app/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          if (!fullMessage) ...[
            const SizedBox(height: 12),
            Center(
              child: TfTextAction(
                label: 'Or log in with another account',
                onPressed: () => Get.offAll(() => const LoginScreen()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}