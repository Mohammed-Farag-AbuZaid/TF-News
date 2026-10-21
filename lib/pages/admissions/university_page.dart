// lib/pages/admissions/university_page.dart
// One university: facts, then the list of ways to get funded there.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/admissions_models.dart';
import 'package:tf_news/authentication/admissions_repository.dart';
import 'package:tf_news/pages/admissions/ad_kit.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openExternalLink(String? href) async {
  if (href == null || href.isEmpty) return;
  final uri = Uri.tryParse(href);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

const Color _partial = Color(0xFFB45309);

/// "Full funding" / "Partial funding" / "See details" with a small dot.
class CoverageBadge extends StatelessWidget {
  final String coverage;
  const CoverageBadge({super.key, required this.coverage});

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color color;
    switch (coverage) {
      case 'full':
        label = 'Full funding';
        color = tfGood;
        break;
      case 'partial':
        label = 'Partial funding';
        color = _partial;
        break;
      default:
        label = 'See details';
        color = tfMuted;
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class UniversityPage extends StatefulWidget {
  const UniversityPage({super.key});

  @override
  State<UniversityPage> createState() => _UniversityPageState();
}

class _UniversityPageState extends State<UniversityPage> {
  static const _filters = <String, String>{
    'all': 'All',
    'full': 'Full funding',
    'partial': 'Partial funding',
    'own': "University's own",
    'external': 'External programs',
  };

  Future<List<Object?>>? _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final id = int.tryParse(Get.parameters['id'] ?? '');
    if (id == null) return;
    final repo = AdmissionsRepository();
    _future = Future.wait<Object?>([repo.getUniversity(id), repo.getWays(id)]);
  }

  bool _matches(ScholarshipWay w) {
    switch (_filter) {
      case 'full':
        return w.coverage == 'full';
      case 'partial':
        return w.coverage == 'partial';
      case 'own':
        return !w.isExternal;
      case 'external':
        return w.isExternal;
      default:
        return true;
    }
  }

  Widget _page(List<Widget> Function(BuildContext, TfLayout) slivers) =>
      TfPage(backLabel: 'Universities', slivers: slivers);

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return _notFound();

    return FutureBuilder<List<Object?>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _page((c, l) => [l.gap(48), l.box(const TfRowSkeletons(count: 4))]);
        }
        if (snap.hasError) {
          debugPrint('University failed to load: ${snap.error}');
          return _page((c, l) => [
                l.box(TfEmpty(
                  title: 'We could not load this',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Try again',
                  onAction: () => setState(_load),
                )),
              ]);
        }
        final uni = snap.data![0] as University?;
        final ways = sortWays(snap.data![1] as List<ScholarshipWay>);
        if (uni == null) return _notFound();
        return _content(uni, ways);
      },
    );
  }

  Widget _notFound() => _page((c, l) => [
        l.box(TfEmpty(
          title: 'University not found',
          message: 'The link may be incomplete.',
          actionLabel: 'See all universities',
          onAction: () => Get.offAllNamed('/study/universities'),
        )),
      ]);

  Widget _content(University uni, List<ScholarshipWay> ways) {
    final full = ways.where((w) => w.coverage == 'full').length;
    final partial = ways.where((w) => w.coverage == 'partial').length;
    final shown = ways.where(_matches).toList();

    return _page((context, l) => [
          l.gap(l.small ? 28 : 48),
          l.box(Text(
            'QS ${uni.qsRankText}  ·  ${uni.country}  ·  ${uni.region}',
            style: const TextStyle(color: tfMuted, fontSize: 13),
          )),
          l.gap(10),
          l.box(TfTitle(title: uni.name, small: l.small)),
          l.gap(28),
          l.box(AdFacts(items: [
            AdFact('Ways to get funded', '${ways.length}'),
            AdFact('Full funding', '$full', color: full > 0 ? tfGood : null),
            AdFact('Partial funding', '$partial'),
          ])),
          if (uni.website.isNotEmpty) ...[
            l.gap(12),
            l.box(Align(
              alignment: Alignment.centerLeft,
              child: TfTextAction(
                label: 'Official website  ·  ${uni.websiteHost}',
                icon: Icons.open_in_new,
                onPressed: () => openExternalLink(uni.website),
              ),
            )),
          ],
          l.gap(l.small ? 40 : 56),
          l.box(const AdSectionTitle('Ways to get funded')),
          l.gap(14),
          if (ways.length > 2) ...[
            l.box(TfTabs(
              items: _filters.values.toList(),
              selected: _filters[_filter]!,
              onSelected: (v) => setState(() =>
                  _filter = _filters.entries.firstWhere((e) => e.value == v).key),
            )),
            l.gap(8),
          ],
          if (ways.isEmpty)
            l.box(_emptyWays(uni))
          else if (shown.isEmpty)
            l.box(TfEmpty(
              title: 'Nothing in this group',
              actionLabel: 'Show all',
              onAction: () => setState(() => _filter = 'all'),
            ))
          else
            SliverMainAxisGroup(
              slivers: [
                l.box(const Divider(height: 1, thickness: 0.5, color: tfHair)),
                l.rows(shown.length, (_, i) {
                  final w = shown[i];
                  return AdRow(
                    overlineWidget: Row(
                      children: [
                        CoverageBadge(coverage: w.coverage),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            w.isExternal ? 'External program' : "University's own",
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: tfMuted, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    title: w.title,
                    subtitle: w.provider.isNotEmpty ? 'By ${w.provider}' : null,
                    onTap: () => Get.toNamed(
                        '/admissions/university/${uni.uniId}/way/${w.wayNo}'),
                  );
                }),
              ],
            ),
          l.gap(24),
          l.box(const AdNote(
              'Details are copied from official sources, with the source linked next to each passage. Always confirm deadlines on the official site before applying.')),
        ]);
  }

  Widget _emptyWays(University uni) {
    return TfEmpty(
      title: uni.researched
          ? 'No verified scholarship route found yet'
          : 'We are still researching this university',
      message: uni.researched
          ? "We only list routes we could confirm on official pages. Check the university's own website for current funding."
          : 'Check back soon.',
      actionLabel: uni.website.isNotEmpty ? 'Visit official website' : null,
      onAction: uni.website.isNotEmpty ? () => openExternalLink(uni.website) : null,
    );
  }
}