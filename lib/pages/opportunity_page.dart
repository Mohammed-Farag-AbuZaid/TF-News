import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tf_news/data/opportunity_model.dart';
import 'package:tf_news/data/opportunity_repository.dart'; 
import 'package:tf_news/pages/widgets/info_column.dart';

class OpportunityPage extends StatelessWidget {
  const OpportunityPage({super.key});

  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null) return;
    final uri = Uri.parse(href);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
   
    final String? id = Get.parameters['id'];

    
    if (id == null || id.isEmpty) {
      return _buildNotFound(context);
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: FutureBuilder<Opportunity?>(
          future: OpportunityRepository().getOpportunityById(id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Something went wrong: ${snapshot.error}'));
            }

            final opportunity = snapshot.data;

            if (opportunity == null) {
              return _buildNotFound(context);
            }

            return ListView(
              children: [
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoColumn(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opportunity.title,
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          Markdown(
                            data: opportunity.aboutMarkdown,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            onTapLink: _onTapLink,
                            styleSheet: MarkdownStyleSheet.fromTheme(
                              Theme.of(context),
                            ).copyWith(
                              p: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotFound(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Opportunity not found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}