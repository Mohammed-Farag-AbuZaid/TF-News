import 'package:flutter/material.dart';
import 'package:tf_news/common/widgets/images/rounded_image.dart';
import 'package:tf_news/utils/constants/image_strings.dart';

class OpportunityCard extends StatelessWidget {
  const OpportunityCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 500,
        height: 350,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const TRoundedImage(imagePath: TImages.google),
            const SizedBox(height: 16),
            Text(
              'Google Summer of Code 2024',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Google Summer of Code is a global program focused on bringing more student developers into open source software development.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Deadline: March 25, 2024',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Explore'),
            ),
          ],
        ),
      ),
    );
  }
}

