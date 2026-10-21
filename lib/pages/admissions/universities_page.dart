// lib/pages/admissions/universities_page.dart
// Browse by university: region tabs, country picker, search, one long list.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/admissions_models.dart';
import 'package:tf_news/authentication/admissions_programs.dart';
import 'package:tf_news/authentication/admissions_repository.dart';
import 'package:tf_news/pages/admissions/ad_kit.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';

class UniversitiesPage extends StatefulWidget {
  const UniversitiesPage({super.key});

  @override
  State<UniversitiesPage> createState() => _UniversitiesPageState();
}

class _UniversitiesPageState extends State<UniversitiesPage> {
  static const Map<String, String> _sorts = {
    'rank': 'QS ranking',
    'ways': 'Most scholarships',
    'az': 'A to Z',
  };

  final AdmissionsRepository _repo = AdmissionsRepository();
  final TextEditingController _searchCtrl = TextEditingController();
  late Future<List<University>> _future;
  late AdFilters _f;
  String _query = '';
  String _sort = 'rank';

  @override
  void initState() {
    super.initState();
    _f = AdFilters.fromArgs(Get.arguments);
    _future = _repo.getUniversities();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<University> _filter(List<University> all) {
    final q = _query.trim().toLowerCase();
    final list = all.where((u) {
      if (_f.regions.isNotEmpty && !_f.regions.contains(adRegionOf(u))) return false;
      if (_f.countries.isNotEmpty && !_f.countries.contains(u.country)) return false;
      if (_f.withWaysOnly && u.waysFound == 0) return false;
      if (q.isNotEmpty && !'${u.name} ${u.country}'.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();

    if (_sort == 'ways') {
      list.sort((a, b) {
        final r = b.waysFound.compareTo(a.waysFound);
        return r != 0 ? r : a.uniId.compareTo(b.uniId);
      });
    } else if (_sort == 'az') {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  Map<String, int> _regionCounts(List<University> all) {
    final m = <String, int>{};
    for (final u in all) {
      final r = adRegionOf(u);
      m[r] = (m[r] ?? 0) + 1;
    }
    return m;
  }

  Map<String, int> _countryCounts(List<University> all) {
    final m = <String, int>{};
    for (final u in all) {
      if (u.country.isEmpty) continue;
      if (_f.regions.isNotEmpty && !_f.regions.contains(adRegionOf(u))) continue;
      m[u.country] = (m[u.country] ?? 0) + 1;
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
    return FutureBuilder<List<University>>(
      future: _future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final failed = snap.hasError;
        final all = snap.data ?? const <University>[];
        final filtered = (loading || failed) ? const <University>[] : _filter(all);

        return TfPage(
          backLabel: 'Admissions',
          slivers: (context, l) => [
            l.gap(l.small ? 28 : 48),
            l.box(TfTitle(
              title: 'Universities',
              subtitle:
                  'The top universities worldwide, and how an Egyptian student can fund each one.',
              small: l.small,
            )),
            l.gap(20),
            l.box(const Align(
                alignment: Alignment.centerLeft,
                child: AdModeSwitch(mode: 0))),
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
                    hint: 'Search university or country',
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
                showWithWays: true,
              )),
            ],
            l.gap(20),
            if (loading)
              l.box(const TfRowSkeletons(count: 6))
            else if (failed)
              l.box(TfEmpty(
                title: 'The university list did not load',
                message: 'Check your connection and try again.',
                actionLabel: 'Try again',
                onAction: () =>
                    setState(() {
                  _future = _repo.getUniversities(refresh: true);
                }),
              ))
            else if (filtered.isEmpty)
              l.box(TfEmpty(
                title: 'No university matches',
                message: 'Try a different spelling, or clear the filters.',
                actionLabel: 'Clear filters',
                onAction: _clearAll,
              ))
            else
              SliverMainAxisGroup(
                slivers: [
                  l.box(Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${filtered.length} ${filtered.length == 1 ? 'university' : 'universities'}',
                      style: const TextStyle(color: tfMuted, fontSize: 13),
                    ),
                  )),
                  l.box(const Divider(height: 1, thickness: 0.5, color: tfHair)),
                  l.rows(
                    filtered.length,
                    (_, i) => AdUniRow(key: ValueKey(filtered[i].uniId), u: filtered[i]),
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}