// lib/authentication/login_screen.dart
// Contains: LoginScreen, LoginForm
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/auth_kit.dart';
import 'package:tf_news/authentication/forget_password_screen.dart';
import 'package:tf_news/authentication/login_controller.dart';
import 'package:tf_news/utils/popups/loaders.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:tf_news/utils/validators/validation.dart';
import 'package:url_launcher/url_launcher.dart';

// NOTE: the "Sign in with Google" button stays out, as before.
// LoginController.googleLogin() still exists if you want to bring it back.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AuthFrame(
      showLogo: true,
      title: 'Welcome back',
      subtitle: 'Sign in with your TF account.',
      child: LoginForm(),
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    return Form(
      key: controller.loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller.email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: (value) => TValidator.validateEmail(value),
            decoration: authInput('Email', Icons.mail_outline),
          ),
          const SizedBox(height: 14),
          Obx(
            () => TextFormField(
              controller: controller.password,
              obscureText: controller.hidePassword.value,
              autofillHints: const [AutofillHints.password],
              validator: (value) =>
                  TValidator.validateEmptyText('Password', value),
              onFieldSubmitted: (_) => controller.emailAndPasswordLogin(),
              decoration: authInput(
                'Password',
                Icons.lock_outline,
                suffix: IconButton(
                  tooltip: controller.hidePassword.value
                      ? 'Show password'
                      : 'Hide password',
                  icon: Icon(controller.hidePassword.value
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                  onPressed: () => controller.hidePassword.value =
                      !controller.hidePassword.value,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Obx(
                () => InkWell(
                  onTap: () =>
                      controller.rememberMe.value = !controller.rememberMe.value,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.rememberMe.value
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 22,
                          color: controller.rememberMe.value
                              ? tfAccent
                              : tfMuted,
                        ),
                        const SizedBox(width: 8),
                        const Text('Remember me',
                            style: TextStyle(color: tfInk, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              TfTextAction(
                label: 'Forgot password?',
                onPressed: () => Get.to(() => const ForgetPassword()),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TfPrimaryButton(
            label: 'Sign in',
            expand: true,
            onPressed: () => controller.emailAndPasswordLogin(),
          ),
          const SizedBox(height: 12),
          Center(
            child: TfTextAction(
              label: 'Create a TF account',
              onPressed: () async {
                final url = Uri.parse('https://tfunions.vercel.app/');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  TLoaders.errorSnackBar(
                    title: 'Error',
                    message: 'Could not open the link. Please try again.',
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}