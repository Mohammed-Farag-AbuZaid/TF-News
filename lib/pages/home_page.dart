import 'package:flutter/material.dart';
import 'package:tf_news/data/opportunity_model.dart';
import 'package:tf_news/data/opportunity_repository.dart';
import 'package:tf_news/pages/widgets/nav_bar.dart';
import 'package:tf_news/pages/widgets/opportunities_header.dart';
import 'package:tf_news/pages/widgets/opportunity_card.dart';
import 'package:tf_news/pages/widgets/status_filter.dart';
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
                Column(
                  children: [
                    TopicRelatedFilter(),
                    const SizedBox(height: 16),
                    StatusFilter(),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OpportunitiesHeader(),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Opportunity>>(
                        future: OpportunityRepository().getOpportunities(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text('Something went wrong: ${snapshot.error}'),
                              ),
                            );
                          }

                          final opportunities = snapshot.data ?? [];

                          if (opportunities.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No opportunities yet')),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 500,
                              mainAxisExtent: 350,
                              crossAxisSpacing: 35,
                              mainAxisSpacing: 35,
                            ),
                            itemCount: opportunities.length,
                            itemBuilder: (context, index) => OpportunityCard(
                              opportunity: opportunities[index],
                            ),
                          );
                        },
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