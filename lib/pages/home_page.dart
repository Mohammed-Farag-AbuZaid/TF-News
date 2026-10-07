import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/data/opportunity_repository.dart';
import 'package:tf_news/data/opportunity_section.dart';
import 'package:tf_news/utils/constants/colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<Map<String, int>> _openCounts;

  @override
  void initState() {
    super.initState();
    _openCounts = OpportunityRepository().getOpenCounts();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('TF News',
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 28),
                Text('Welcome back, Bob!',
                    style: t.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 6),
                Text(
                    'Stay informed with the latest news and updates that interest ambitious students like you.',
                    style: t.titleMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 600 ? 2 : 1;
                    return FutureBuilder<Map<String, int>>(
                      future: _openCounts,
                      builder: (context, snapshot) {
                        final counts = snapshot.data; // null while loading/error
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: OpportunitySection.all.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            mainAxisExtent: 230,
                          ),
                          itemBuilder: (_, i) {
                            final section = OpportunitySection.all[i];
                            return _SectionCard(
                              section: section,
                              openCount:
                                  counts == null ? null : (counts[section.id] ?? 0),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final OpportunitySection section;
  final int? openCount; // null = still loading (or failed): show nothing

  const _SectionCard({required this.section, required this.openCount});

  @override
  Widget build(BuildContext context) {
    final count = openCount;
    return Material(
      color: TColors.primaryBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: TColors.primary),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(section.route),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(section.icon, color: TColors.primary, size: 28),
              const SizedBox(height: 14),
              Text(
                section.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                section.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              Row(
                children: [
                  if (count != null)
                    Text(
                      count == 0 ? 'See what\'s coming' : '$count open now',
                      style: TextStyle(
                        color: TColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const Spacer(),
                  Icon(Icons.arrow_forward, color: TColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}