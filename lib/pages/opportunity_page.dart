import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tf_news/data/opportunity_model.dart';
import 'package:tf_news/data/opportunity_repository.dart';
import 'package:tf_news/pages/widgets/filter_item.dart';
import 'package:tf_news/utils/constants/colors.dart';

class OpportunityPage extends StatefulWidget {
  const OpportunityPage({super.key});

  @override
  State<OpportunityPage> createState() => _OpportunityPageState();
}

class _OpportunityPageState extends State<OpportunityPage> {
  String _selectedSection = 'About';

  final List<FilterItem> _sections = const [
    FilterItem('About', Icons.info_outline),
    FilterItem('Requirements', Icons.checklist),
    FilterItem('Benefits', Icons.card_giftcard),
    FilterItem('Guide', Icons.rule_outlined),
  ];

  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null) return;
    final uri = Uri.parse(href);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getMarkdown(Opportunity o) {
    switch (_selectedSection) {
      case 'Requirements':
        return o.requirementsMarkdown;
      case 'Benefits':
        return o.benefitsMarkdown;
      case 'Guide':
        return o.guidelinesMarkdown;
      default:
        return o.aboutMarkdown;
    }
  }

  String _deadlineText(Opportunity o) {
    final diff = o.deadline.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Deadline passed';
    if (diff == 0) return 'Deadline is today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  Color _deadlineColor(Opportunity o) {
    final diff = o.deadline.difference(DateTime.now()).inDays;
    if (diff < 0) return Colors.grey;
    if (diff <= 3) return Colors.red;
    if (diff <= 7) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final String? id = Get.parameters['id'];

    if (id == null || id.isEmpty) return _buildNotFound();

    return Scaffold(
      body: FutureBuilder<Opportunity?>(
        future: OpportunityRepository().getOpportunityById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          final opportunity = snapshot.data;
          if (opportunity == null) return _buildNotFound();

          return _buildContent(opportunity);
        },
      ),
    );
  }

  Widget _buildContent(Opportunity opportunity) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      children: [
        // Back button + breadcrumb
        Row(
          children: [
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios_new, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Title + meta row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category + Must-know badge
                  Row(
                    children: [
                      if (opportunity.mustKnow) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'MUST-KNOW',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    opportunity.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opportunity.shortDescription,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Info card
            Container(
              width: 220,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    Icons.timer_outlined,
                    'Deadline',
                    _deadlineText(opportunity),
                    valueColor: _deadlineColor(opportunity),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final uri = Uri.parse(opportunity.link);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Apply Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 24),

        // Section tabs + content
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar
            Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      'SECTIONS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[500],
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  ..._sections.map(
                    (item) => FilterTile(
                      icon: item.icon,
                      label: item.label,
                      isSelected: item.label == _selectedSection,
                      onTap: () => setState(() => _selectedSection = item.label),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),

            // Markdown content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  key: ValueKey(_selectedSection),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: MarkdownBody(
                    data: _getMarkdown(opportunity),
                    onTapLink: _onTapLink,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context),
                    ).copyWith(
                      p: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.7,
                      ),
                      h2: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      h3: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {
    Color? iconColor,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: iconColor ?? Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotFound() {
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