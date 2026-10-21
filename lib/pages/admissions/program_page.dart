// lib/pages/admissions/program_page.dart
// One program: what it is, and every university where it can be used.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/admissions_models.dart';
import 'package:tf_news/authentication/admissions_programs.dart';
import 'package:tf_news/authentication/admissions_repository.dart';
import 'package:tf_news/pages/admissions/ad_kit.dart';
import 'package:tf_news/pages/admissions/university_page.dart' show CoverageBadge;
import 'package:tf_news/utils/ui/tf_minimal.dart';

class ProgramPage extends StatefulWidget {
  const ProgramPage({super.key});

  @override
  State<ProgramPage> createState() => _ProgramPageState();
}

class _ProgramPageState extends State<ProgramPage> {
  static const String _allRegions = 'All regions';

  final AdmissionsRepository _repo = AdmissionsRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  late Future<List<Program>> _future;
  String _region = _allRegions;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _repo.getPrograms();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _page(List<Widget> Function(BuildContext, TfLayout) slivers) =>
      TfPage(backLabel: 'Programs', slivers: slivers);

  @override
  Widget build(BuildContext context) {
    final key = Get.parameters['key'] ?? '';
    return FutureBuilder<List<Program>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return _page((c, l) => [l.gap(48), l.box(const TfRowSkeletons(count: 4))]);
        }
        if (snap.hasError) {
          debugPrint('Program failed to load: ${snap.error}');
          return _page((c, l) => [
                l.box(TfEmpty(
                  title: 'We could not load this',
                  message: 'Check your connection and try again.',
                  actionLabel: 'Try again',
                  onAction: () =>
                      setState(() {
                    _future = _repo.getPrograms(refresh: true);
                  }),
                )),
              ]);
        }
        Program? p;
        for (final x in snap.data ?? const <Program>[]) {
          if (x.key == key) p = x;
        }
        if (p == null) {
          return _page((c, l) => [
                l.box(TfEmpty(
                  title: 'Program not found',
                  message: 'The link may be old or incomplete.',
                  actionLabel: 'See all programs',
                  onAction: () => Get.offNamed('/study/programs'),
                )),
              ]);
        }
        return _content(p);
      },
    );
  }

  String _overview(Program p) {
    final sec =
        parseWayMarkdown(p.entries.first.way.markdown).sections['Overview'] ?? '';
    final text = sec
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^>\s?'), '').trim())
        .where((l) => l.isNotEmpty && !l.startsWith('Source:'))
        .join(' ');
    return text.length > 320 ? '${text.substring(0, 320).trimRight()}...' : text;
  }

  Widget _content(Program p) {
    final regions = p.regions.toList()
      ..sort((a, b) => adRegionIndex(a).compareTo(adRegionIndex(b)));
    final q = _query.trim().toLowerCase();
    final shown = p.entries.where((e) {
      if (_region != _allRegions && adRegionOf(e.uni) != _region) return false;
      if (q.isNotEmpty &&
          !'${e.uni.name} ${e.uni.country}'.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
    final overview = _overview(p);
    final levels = kLevels.where(p.levels.contains).join(', ');

    return _page((context, l) => [
          l.gap(l.small ? 28 : 48),
          l.box(Align(
              alignment: Alignment.centerLeft,
              child: CoverageBadge(coverage: p.coverage))),
          l.gap(10),
          l.box(TfTitle(title: p.name, small: l.small)),
          if (overview.isNotEmpty) ...[
            l.gap(14),
            l.box(ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Text(overview,
                  style: const TextStyle(
                      color: tfMuted, fontSize: 17, height: 1.55)),
            )),
          ],
          l.gap(28),
          l.box(AdFacts(items: [
            AdFact('Universities', '${p.uniCount}'),
            AdFact('Countries', '${p.countries.length}'),
            if (levels.isNotEmpty) AdFact('Levels', levels),
          ])),
          l.gap(l.small ? 40 : 56),
          l.box(const AdSectionTitle('Where you can use it')),
          l.gap(14),
          l.box(TfTabs(
            items: [_allRegions, ...regions],
            selected: _region,
            onSelected: (r) => setState(() => _region = r),
          )),
          if (p.entries.length > 6) ...[
            l.gap(12),
            l.box(Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: TfSearch(
                  controller: _searchCtrl,
                  hint: 'Search these universities',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            )),
          ],
          l.gap(12),
          if (shown.isEmpty)
            l.box(TfEmpty(
              title: 'No universities in this group',
              actionLabel: 'Show all',
              onAction: () {
                _searchCtrl.clear();
                setState(() {
                  _region = _allRegions;
                  _query = '';
                });
              },
            ))
          else
            SliverMainAxisGroup(
              slivers: [
                l.box(const Divider(height: 1, thickness: 0.5, color: tfHair)),
                l.rows(shown.length, (_, i) {
                  final e = shown[i];
                  return AdRow(
                    overlineWidget: Row(
                      children: [
                        CoverageBadge(coverage: e.way.coverage),
                        const SizedBox(width: 10),
                        Text('QS ${e.uni.qsRankText}',
                            style:
                                const TextStyle(color: tfMuted, fontSize: 12)),
                      ],
                    ),
                    title: e.uni.name,
                    subtitle: '${e.uni.country}  ·  ${adRegionOf(e.uni)}',
                    onTap: () => Get.toNamed(
                        '/admissions/university/${e.uni.uniId}/way/${e.way.wayNo}'),
                  );
                }),
              ],
            ),
          l.gap(24),
          l.box(const AdNote(
              'Requirements and deadlines can differ by university. Open one to see the official details and the source link. Always confirm on the official site before applying.')),
        ]);
  }
}