import 'package:flutter/material.dart';
import 'package:tf_news/utils/constants/image_strings.dart';
import 'package:tf_news/utils/constants/sizes.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({
    super.key,
    required this.dark,
  });

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image(
          height: 150,
          image: AssetImage(
            dark ? TImages.tfLogo : TImages.tfLogo,
          ),
        ),
        Text(
          'Welcome Back',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: TSizes.sm),
        Text(
          'Login Using Your TF Account',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
