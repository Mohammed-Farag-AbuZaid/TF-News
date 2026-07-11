import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tf_news/pages/widgets/info_column.dart';

class OpportunityPage extends StatelessWidget {
  const OpportunityPage({super.key});

  static const String aboutMarkdown = '''
Google Summer of Code (GSoC) is a **global, online program** focused on bringing new contributors into open source software development. Since 2005, GSoC has brought together thousands of students with open source organizations to work on real-world projects over a 12+ week period.

## What You'll Do

Participants work remotely with an open source organization on a project of their choosing, guided by mentors from that organization. You'll gain:

- Hands-on experience with **real production codebases**
- Direct mentorship from experienced developers
- A stipend for your contributions
- A certificate and public recognition

### Eligibility

To apply, you must:

1. Be at least 18 years old
2. Be a student or new to open source development
3. Be eligible to work in your country of residence

> Note: You do *not* need to be enrolled full-time — part-time students and recent graduates may also qualify.

For more details, visit the [official GSoC website](https://summerofcode.withgoogle.com).

---

**Program Duration:** 12–22 weeks  
**Time Commitment:** ~20 hours/week
''';

  Future<void> _onTapLink(String text, String? href, String title) async {
    if (href == null) return;
    final uri = Uri.parse(href);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
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
                        'Google Summer of Code 2024',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Markdown(
                        data: aboutMarkdown,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onTapLink: _onTapLink,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(
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
        ),
      ),
    );
  }
}
