// lib/authentication/login_screen.dart
// Contains: LoginScreen, LoginHeader, LoginForm
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:tf_news/authentication/forget_password_screen.dart';
import 'package:tf_news/authentication/login_controller.dart';
import 'package:tf_news/common/common_widgets.dart';
import 'package:tf_news/utils/constants/image_strings.dart';
import 'package:tf_news/utils/constants/sizes.dart';
import 'package:tf_news/utils/helpers/helper_functions.dart';
import 'package:tf_news/utils/popups/loaders.dart';
import 'package:tf_news/utils/validators/validation.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = THelperFunctions.isDarkMode(context);

    // NOTE: the "Sign in with Google" button was commented out in the original.
    // LoginController.googleLogin() still exists if you want to bring it back.
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: TSpacingStyle.paddingWithAppBarHieght,
          child: Column(
            children: [
              LoginHeader(dark: dark),
              const LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key, required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Image(height: 150, image: AssetImage(TImages.tfLogo)),
        Text('Welcome Back', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: TSizes.sm),
        Text(
          'Login Using Your TF Account',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TSizes.spaceBwSections),
        child: Column(
          children: [
            TextFormField(
              controller: controller.email,
              validator: (value) => TValidator.validateEmail(value),
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: TSizes.spaceBwInputFields),

            Obx(
              () => TextFormField(
                controller: controller.password,
                validator: (value) =>
                    TValidator.validateEmptyText('Password', value),
                obscureText: controller.hidePassword.value,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Iconsax.password_check),
                  suffixIcon: IconButton(
                    icon: Icon(
                      controller.hidePassword.value
                          ? Iconsax.eye_slash
                          : Iconsax.eye,
                    ),
                    onPressed: () => controller.hidePassword.value =
                        !controller.hidePassword.value,
                  ),
                ),
              ),
            ),
            const SizedBox(height: TSizes.spaceBwInputFields / 2),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Obx(
                      () => Checkbox(
                        value: controller.rememberMe.value,
                        onChanged: (value) => controller.rememberMe.value =
                            !controller.rememberMe.value,
                      ),
                    ),
                    const Text("Remember me"),
                  ],
                ),
                TextButton(
                  onPressed: () => Get.to(() => const ForgetPassword()),
                  child: const Text("Forgot password?"),
                ),
              ],
            ),
            const SizedBox(height: TSizes.spaceBwSections),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.emailAndPasswordLogin(),
                child: const Text('Sign In'),
              ),
            ),
            const SizedBox(height: TSizes.spaceBwItems),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  final Uri url = Uri.parse("https://tfunions.vercel.app/");
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    TLoaders.errorSnackBar(
                      title: 'Error',
                      message: 'Could not open the link. Please try again.',
                    );
                  }
                },
                child: const Text("Create a TF account."),
              ),
            ),
          ],
        ),
      ),
    );
  }
}