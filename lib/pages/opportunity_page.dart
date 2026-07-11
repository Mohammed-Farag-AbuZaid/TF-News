import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/info_column.dart';

class OpportunityPage extends StatelessWidget {
  const OpportunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InfoColumn(),
                SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Google Summer of Code 2024', style: Theme.of(context).textTheme.headlineLarge),
                      ],
                    )
                  ],
                )

              ],
            )
          ],
        ),
      ),
    );
  }
}