import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/nav_bar.dart';
import 'package:tf_news/pages/widgets/opportunities_header.dart';
import 'package:tf_news/pages/widgets/opportunity_card.dart';
import 'package:tf_news/pages/widgets/topic_related_filter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            const NavBar(),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TopicRelatedFilter(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OpportunitiesHeader(),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 500, // fixed card width
                          mainAxisExtent: 350,     // fixed card height
                          crossAxisSpacing: 35,
                          mainAxisSpacing: 35,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, index) => const OpportunityCard(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}