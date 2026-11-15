// lib/authentication/login_screen.dart
// Contains: LoginScreen, LoginForm (with in-app Account Creation & Saved Accounts)
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/auth_kit.dart';
import 'package:tf_news/authentication/forget_password_screen.dart';
import 'package:tf_news/authentication/login_controller.dart';
import 'package:tf_news/utils/constants/image_strings.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:tf_news/utils/validators/validation.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    return Obx(
      () => AuthFrame(
        showLogo: true,
        title: controller.isRegisterMode.value
            ? 'Create your TF Passport'
            : 'Welcome back',
        subtitle: controller.isRegisterMode.value
            ? 'One account for TF News, TF Unions, STEM Union, and STEM Shop.'
            : 'Sign in with your saved TF Passport, Google, or email.',
        child: const LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatelessWidget {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LoginController());
    return Obx(() {
      final isReg = controller.isRegisterMode.value;
      final saved = controller.savedAccounts;

      return Form(
        key: controller.loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Saved accounts on this device (1-tap retrieval)
            if (saved.isNotEmpty && !isReg) ...[
              const Text(
                'Saved accounts on this device',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tfMuted,
                ),
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  for (final acc in saved)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => controller.quickLoginWithSavedAccount(acc),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: tfCanvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tfHair),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: tfTealSoft,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: tfTealBorder),
                                ),
                                child: Text(
                                  ((acc['name'] ?? acc['email'] ?? 'U')
                                          .toString()
                                          .trim()
                                          .isNotEmpty
                                      ? (acc['name'] ?? acc['email'])
                                          .toString()
                                          .trim()[0]
                                          .toUpperCase()
                                      : 'U'),
                                  style: const TextStyle(
                                    color: tfGood,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (acc['name'] ?? 'TF Scholar').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: tfInk,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    Text(
                                      (acc['email'] ?? '').toString(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: tfMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Remove saved account',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: tfMuted,
                                ),
                                onPressed: () => controller.removeSavedAccount(
                                  (acc['email'] ?? '').toString(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Segmented Switch: Sign in / Create account
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tfTile,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tfHair),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeTab(
                      label: 'Sign in',
                      active: !isReg,
                      onTap: () => controller.isRegisterMode.value = false,
                    ),
                  ),
                  Expanded(
                    child: _ModeTab(
                      label: 'Create account',
                      active: isReg,
                      onTap: () => controller.isRegisterMode.value = true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Google Sign-In
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () => controller.googleLogin(),
                style: OutlinedButton.styleFrom(
                  backgroundColor: tfPaper,
                  foregroundColor: tfInk,
                  side: const BorderSide(color: tfHair),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Image(
                  width: 19,
                  height: 19,
                  image: AssetImage(TImages.google),
                ),
                label: const Text(
                  'Continue with Google',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Row(
              children: [
                Expanded(child: Divider(color: tfHair, height: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or with email',
                    style: TextStyle(color: tfMuted, fontSize: 12),
                  ),
                ),
                Expanded(child: Divider(color: tfHair, height: 1)),
              ],
            ),
            const SizedBox(height: 14),

            if (isReg) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: controller.firstName,
                      validator: (v) =>
                          TValidator.validateEmptyText('First name', v),
                      decoration: authInput('First name', Icons.person_outline),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: controller.lastName,
                      validator: (v) =>
                          TValidator.validateEmptyText('Last name', v),
                      decoration: authInput('Last name', Icons.person_outline),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.phone,
                keyboardType: TextInputType.phone,
                decoration: authInput('WhatsApp / Phone (+20)', Icons.phone_outlined),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.academicLevel.value,
                      isExpanded: true,
                      decoration: authInput('Track', Icons.school_outlined),
                      items: const [
                        DropdownMenuItem(value: 'STEM', child: Text('STEM')),
                        DropdownMenuItem(
                            value: 'Thanawy', child: Text('Thanawy')),
                        DropdownMenuItem(
                            value: 'Prep School', child: Text('Prep School')),
                        DropdownMenuItem(
                            value: 'University', child: Text('University')),
                        DropdownMenuItem(value: 'IGCSE', child: Text('IGCSE')),
                        DropdownMenuItem(value: 'Azhar', child: Text('Azhar')),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.academicLevel.value = v;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.grade.value,
                      isExpanded: true,
                      decoration: authInput('Grade', Icons.grade_outlined),
                      items: const [
                        DropdownMenuItem(
                            value: 'Grade 9', child: Text('Grade 9')),
                        DropdownMenuItem(
                            value: 'Grade 10', child: Text('Grade 10')),
                        DropdownMenuItem(
                            value: 'Grade 11', child: Text('Grade 11')),
                        DropdownMenuItem(
                            value: 'Grade 12', child: Text('Grade 12')),
                        DropdownMenuItem(
                            value: 'Undergrad', child: Text('Undergrad')),
                        DropdownMenuItem(value: 'Grad', child: Text('Grad')),
                      ],
                      onChanged: (v) {
                        if (v != null) controller.grade.value = v;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller.school,
                decoration:
                    authInput('School / University', Icons.account_balance_outlined),
              ),
              const SizedBox(height: 12),
            ],

            TextFormField(
              controller: controller.email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              validator: (value) => TValidator.validateEmail(value),
              decoration: authInput('Email', Icons.mail_outline),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: controller.password,
              obscureText: controller.hidePassword.value,
              autofillHints: isReg
                  ? const [AutofillHints.newPassword]
                  : const [AutofillHints.password],
              validator: (value) {
                if (value == null || value.trim().length < 6) {
                  return 'Password must be at least 6 characters.';
                }
                return null;
              },
              onFieldSubmitted: (_) => isReg
                  ? controller.registerAccount()
                  : controller.emailAndPasswordLogin(),
              decoration: authInput(
                'Password',
                Icons.lock_outline,
                suffix: IconButton(
                  tooltip: controller.hidePassword.value
                      ? 'Show password'
                      : 'Hide password',
                  icon: Icon(
                    controller.hidePassword.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => controller.hidePassword.value =
                      !controller.hidePassword.value,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                InkWell(
                  onTap: () =>
                      controller.rememberMe.value = !controller.rememberMe.value,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.rememberMe.value
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 20,
                          color: controller.rememberMe.value ? tfAccent : tfMuted,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Keep account saved',
                          style: TextStyle(color: tfInk, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                if (!isReg)
                  TextButton(
                    onPressed: () => Get.to(() => const ForgetPassword()),
                    style: TextButton.styleFrom(
                      foregroundColor: tfAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: const Text(
                      'Forgot password?',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TfPrimaryButton(
              label: isReg ? 'Create account' : 'Sign in',
              expand: true,
              onPressed: () => isReg
                  ? controller.registerAccount()
                  : controller.emailAndPasswordLogin(),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () =>
                    controller.isRegisterMode.value = !isReg,
                child: Text(
                  isReg
                      ? 'Already have an account? Sign in'
                      : 'New here? Create a TF account',
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: tfAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? tfPaper : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? tfHair : Colors.transparent,
          ),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x0A161A22),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? tfInk : tfMuted,
          ),
        ),
      ),
    );
  }
}
