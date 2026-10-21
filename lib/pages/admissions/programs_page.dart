// lib/pages/admissions/programs_page.dart
// Browse by program: scholarships that are not tied to one university.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/admissions_programs.dart';
import 'package:tf_news/authentication/admissions_repository.dart';
import 'package:tf_news/pages/admissions/ad_kit.dart';
import 'package:tf_news/pages/admissions/university_page.dart' show CoverageBadge;
import 'package:tf_news/utils/ui/tf_minimal.dart';

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  static const Map<String, String> _sorts = {
    'unis': 'Most universities',
    'full': 'Full funding first',
    'az': 'A to Z',
  };

  final AdmissionsRepository _repo = AdmissionsRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  late Future<List<Program>> _future;
  late AdFilters _f;
  String _query = '';
  String _sort = 'unis';

  @override
  void initState() {
    super.initState();
    _f = AdFilters.fromArgs(Get.arguments);
    _future = _repo.getPrograms();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Program> _filter(List<Program> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((p) {
      if (_f.regions.isNotEmpty && p.regions.intersection(_f.regions).isEmpty) {
        return false;
      }
      if (_f.countries.isNotEmpty &&
          p.countries.intersection(_f.countries).isEmpty) {
        return false;
      }
      if (_f.coverage != 'any' &&
          !p.entries.any((e) => e.way.coverage == _f.coverage)) {
        return false;
      }
      if (!p.matchesLevels(_f.levels) || !p.matchesFields(_f.fields)) return false;
      if (q.isNotEmpty && !p.searchText.contains(q)) return false;
      return true;
    }).toList();

    int rank(String c) => c == 'full' ? 0 : (c == 'partial' ? 1 : 2);
    if (_sort == 'full') {
      list.sort((a, b) {
        final r = rank(a.coverage).compareTo(rank(b.coverage));
        return r != 0 ? r : b.uniCount.compareTo(a.uniCount);
      });
    } else if (_sort == 'az') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } // default order from buildPrograms is already "most universities"
    return list;
  }

  Map<String, int> _regionCounts(List<Program> all) {
    final m = <String, int>{};
    for (final p in all) {
      for (final r in p.regions) {
        m[r] = (m[r] ?? 0) + 1;
      }
    }
    return m;
  }

  Map<String, int> _countryCounts(List<Program> all) {
    final m = <String, int>{};
    for (final p in all) {
      final seen = <String>{};
      for (final e in p.entries) {
        if (e.uni.country.isEmpty) continue;
        if (_f.regions.isNotEmpty && !_f.regions.contains(adRegionOf(e.uni))) {
          continue;
        }
        seen.add(e.uni.country);
      }
      for (final c in seen) {
        m[c] = (m[c] ?? 0) + 1;
      }
    }
    return m;
  }

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _query = '';
      _f = const AdFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Program>>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final failed = snap.hasError;
        final all = snap.data ?? const <Program>[];
        final filtered = (loading || failed) ? const <Program>[] : _filter(all);

        return TfPage(
          backLabel: 'Admissions',
          slivers: (context, l) => [
            l.gap(l.small ? 28 : 48),
            l.box(TfTitle(
              title: 'Programs',
              subtitle:
                  'Scholarships and initiatives that are not tied to one university, and every university where you can use them.',
              small: l.small,
            )),
            l.gap(20),
            l.box(const Align(
                alignment: Alignment.centerLeft,
                child: AdModeSwitch(mode: 1))),
            l.gap(20),
            l.box(Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520, minWidth: 260),
                  child: TfSearch(
                    controller: _searchCtrl,
                    hint: 'Search program, university or country',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                TfMenu(
                  label: 'Sort',
                  valueLabel: _sorts[_sort]!,
                  value: _sort,
                  options: _sorts,
                  onSelected: (v) => setState(() => _sort = v),
                ),
              ],
            )),
            if (!loading && !failed) ...[
              l.gap(16),
              l.box(AdFilterBar(
                filters: _f,
                onChanged: (f) => setState(() => _f = f),
                regionCounts: _regionCounts(all),
                countryCounts: _countryCounts(all),
                showCoverage: true,
                showContent: true,
              )),
            ],
            l.gap(20),
            if (loading)
              l.box(ValueListenableBuilder<double?>(
                valueListenable: _repo.programsProgress,
                builder: (_, v, __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v == null
                          ? 'Loading programs...'
                          : 'Collecting programs from universities... ${(v * 100).round()}%',
                      style: const TextStyle(color: tfMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        color: tfAccent,
                        backgroundColor: tfTile,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TfRowSkeletons(count: 4),
                  ],
                ),
              ))
            else if (failed)
              l.box(TfEmpty(
                title: 'The programs did not load',
                message: 'Check your connection and try again.',
                actionLabel: 'Try again',
                onAction: () =>
                    setState(() {
                  _future = _repo.getPrograms(refresh: true);
                }),
              ))
            else if (filtered.isEmpty)
              l.box(TfEmpty(
                title: 'No program matches',
                message: 'Try fewer filters, or browse by university instead.',
                actionLabel: 'Clear filters',
                onAction: _clearAll,
              ))
            else
              SliverMainAxisGroup(
                slivers: [
                  l.box(Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${filtered.length} ${filtered.length == 1 ? 'program' : 'programs'}',
                      style: const TextStyle(color: tfMuted, fontSize: 13),
                    ),
                  )),
                  l.box(const Divider(height: 1, thickness: 0.5, color: tfHair)),
                  l.rows(filtered.length, (_, i) => _ProgramRow(p: filtered[i])),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _ProgramRow extends StatelessWidget {
  final Program p;
  const _ProgramRow({required this.p});

  @override
  Widget build(BuildContext context) {
    final regions = p.regions.toList()
      ..sort((a, b) => adRegionIndex(a).compareTo(adRegionIndex(b)));
    final shown = regions.take(3).join(', ');
    final extra = regions.length > 3 ? ' +${regions.length - 3}' : '';
    final levels = kLevels.where(p.levels.contains).join(', ');
    return AdRow(
      key: ValueKey(p.key),
      overlineWidget: Row(
        children: [
          CoverageBadge(coverage: p.coverage),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              '${p.uniCount} ${p.uniCount == 1 ? 'university' : 'universities'}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: tfMuted, fontSize: 12),
            ),
          ),
        ],
      ),
      title: p.name,
      subtitle: p.entries.first.way.title,
      meta: [if (levels.isNotEmpty) levels, '$shown$extra']
          .where((s) => s.trim().isNotEmpty)
          .join('  ·  '),
      onTap: () => Get.toNamed('/admissions/program/${p.key}'),
    );
  }
}