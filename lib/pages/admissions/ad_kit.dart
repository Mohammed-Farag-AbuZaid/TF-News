// lib/pages/admissions/ad_kit.dart
// Shared pieces for the Admissions flow, built on the minimal TF kit:
// filters, filter bar, country picker, university row, small layout parts.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/admissions_models.dart';
import 'package:tf_news/authentication/admissions_programs.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';

// ---------------------------------------------------------------------------
// Filters
// ---------------------------------------------------------------------------

class AdFilters {
  final Set<String> regions;
  final Set<String> countries;
  final Set<String> levels;
  final Set<String> fields;
  final String coverage; // any | full | partial
  final bool withWaysOnly;

  const AdFilters({
    this.regions = const {},
    this.countries = const {},
    this.levels = const {},
    this.fields = const {},
    this.coverage = 'any',
    this.withWaysOnly = false,
  });

  int get count =>
      regions.length +
      countries.length +
      levels.length +
      fields.length +
      (coverage != 'any' ? 1 : 0) +
      (withWaysOnly ? 1 : 0);

  AdFilters copyWith({
    Set<String>? regions,
    Set<String>? countries,
    Set<String>? levels,
    Set<String>? fields,
    String? coverage,
    bool? withWaysOnly,
  }) =>
      AdFilters(
        regions: regions ?? this.regions,
        countries: countries ?? this.countries,
        levels: levels ?? this.levels,
        fields: fields ?? this.fields,
        coverage: coverage ?? this.coverage,
        withWaysOnly: withWaysOnly ?? this.withWaysOnly,
      );

  /// Lets shortcuts open a page with filters already set.
  factory AdFilters.fromArgs(dynamic a) {
    if (a is! Map) return const AdFilters();
    Set<String> s(String k) => a[k] is Iterable
        ? {for (final e in a[k] as Iterable) e.toString()}
        : <String>{};
    return AdFilters(
      regions: s('regions'),
      countries: s('countries'),
      levels: s('levels'),
      fields: s('fields'),
      coverage: (a['coverage'] as String?) ?? 'any',
      withWaysOnly: a['withWaysOnly'] == true,
    );
  }
}

// ---------------------------------------------------------------------------
// Small layout parts
// ---------------------------------------------------------------------------

class AdSectionTitle extends StatelessWidget {
  final String text;
  const AdSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: tfInk,
          letterSpacing: -0.6,
        ),
      ),
    );
  }
}

class AdFact {
  final String label;
  final String value;
  final Color? color;
  const AdFact(this.label, this.value, {this.color});
}

/// Label / value pairs between two hairlines.
class AdFacts extends StatelessWidget {
  final List<AdFact> items;
  const AdFacts({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: tfHair, width: 0.5),
        ),
      ),
      child: Wrap(
        spacing: 44,
        runSpacing: 20,
        children: [
          for (final f in items)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(f.label,
                    style: const TextStyle(color: tfMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(f.value,
                    style: TextStyle(
                        color: f.color ?? tfInk,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ],
            ),
        ],
      ),
    );
  }
}

/// A quiet note with a check icon (used for "copied from official sources").
class AdNote extends StatelessWidget {
  final String text;
  const AdNote(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.verified_outlined, size: 16, color: tfMuted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: tfMuted, fontSize: 13, height: 1.5)),
        ),
      ],
    );
  }
}

/// A plain tappable row: overline, title, optional lines, chevron, hairline.
class AdRow extends StatelessWidget {
  final String? overline;
  final Widget? overlineWidget;
  final String title;
  final String? subtitle;
  final String? meta;
  final Color? metaColor;
  final VoidCallback onTap;

  const AdRow({
    super.key,
    this.overline,
    this.overlineWidget,
    required this.title,
    this.subtitle,
    this.meta,
    this.metaColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          hoverColor: const Color(0x08000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (overlineWidget != null)
                        overlineWidget!
                      else if (overline != null && overline!.isNotEmpty)
                        Text(overline!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                const TextStyle(color: tfMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: tfInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: tfMuted, fontSize: 14, height: 1.45)),
                      ],
                      if (meta != null && meta!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(meta!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: metaColor ?? tfMuted,
                                fontSize: 13,
                                fontWeight: metaColor != null
                                    ? FontWeight.w600
                                    : FontWeight.w400)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: tfMuted),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: tfHair),
      ],
    );
  }
}

/// A university as a list row.
class AdUniRow extends StatelessWidget {
  final University u;
  const AdUniRow({super.key, required this.u});

  @override
  Widget build(BuildContext context) {
    final hasWays = u.researched && u.waysFound > 0;
    final status = hasWays
        ? '${u.waysFound} ${u.waysFound == 1 ? 'way' : 'ways'} to get funded'
        : (u.researched ? 'No verified scholarship yet' : 'Research in progress');
    return AdRow(
      overline: 'QS ${u.qsRankText}  ·  ${u.country}',
      title: u.name,
      meta: status,
      metaColor: hasWays ? tfGood : null,
      onTap: () => Get.toNamed('/admissions/university/${u.uniId}'),
    );
  }
}

// ---------------------------------------------------------------------------
// Mode switch (universities | programs)
// ---------------------------------------------------------------------------

class AdModeSwitch extends StatelessWidget {
  final int mode; // 0 universities, 1 programs
  const AdModeSwitch({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    return TfSegmented(
      items: const ['Universities', 'Programs'],
      selected: mode == 0 ? 'Universities' : 'Programs',
      onSelected: (s) {
        final next = s == 'Universities' ? 0 : 1;
        if (next == mode) return;
        WidgetsBinding.instance.addPostFrameCallback((_) =>
            Get.offNamed(next == 0 ? '/study/universities' : '/study/programs'));
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Country picker (searchable sheet, 100+ countries do not fit in a menu)
// ---------------------------------------------------------------------------

class AdPicker extends StatelessWidget {
  final String label;
  final String valueLabel;
  final VoidCallback onTap;
  const AdPicker({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(11),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tfTile,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$label  ',
                style: const TextStyle(color: tfMuted, fontSize: 13)),
            Text(valueLabel,
                style: const TextStyle(
                    color: tfInk, fontSize: 13, fontWeight: FontWeight.w600)),
            const Icon(Icons.expand_more, size: 18, color: tfMuted),
          ],
        ),
      ),
    );
  }
}

/// Returns the chosen country, '' for "all countries", null if dismissed.
Future<String?> adPickCountry(
  BuildContext context,
  Map<String, int> counts,
  Set<String> current,
) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 560),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CountrySheet(
      counts: counts,
      selected: current.isEmpty ? null : current.first,
    ),
  );
}

class _CountrySheet extends StatefulWidget {
  final Map<String, int> counts;
  final String? selected;
  const _CountrySheet({required this.counts, required this.selected});

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final TextEditingController _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Widget _row(String label, int? count, bool selected, String value) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 15,
                      color: tfInk,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
            ),
            if (count != null)
              Text('$count',
                  style: const TextStyle(color: tfMuted, fontSize: 13)),
            if (selected) ...[
              const SizedBox(width: 10),
              const Icon(Icons.check, size: 18, color: tfAccent),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _q.text.trim().toLowerCase();
    final names = widget.counts.keys
        .where((c) => q.isEmpty || c.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) {
        final d = (widget.counts[b] ?? 0).compareTo(widget.counts[a] ?? 0);
        return d != 0 ? d : a.compareTo(b);
      });
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: TfSearch(
                controller: _q,
                hint: 'Find a country',
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  if (q.isEmpty)
                    _row('All countries', null, widget.selected == null, ''),
                  for (final n in names)
                    _row(n, widget.counts[n], widget.selected == n, n),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar (same on phone and desktop)
// ---------------------------------------------------------------------------

class AdFilterBar extends StatelessWidget {
  final AdFilters filters;
  final ValueChanged<AdFilters> onChanged;
  final Map<String, int> regionCounts;
  final Map<String, int> countryCounts;
  final bool showCoverage; // programs
  final bool showContent; // programs: level + field
  final bool showWithWays; // universities

  const AdFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
    required this.regionCounts,
    required this.countryCounts,
    this.showCoverage = false,
    this.showContent = false,
    this.showWithWays = false,
  });

  static const String _allRegions = 'All regions';

  @override
  Widget build(BuildContext context) {
    final f = filters;
    final regions = regionCounts.keys.toList()
      ..sort((a, b) {
        final r = adRegionIndex(a).compareTo(adRegionIndex(b));
        return r != 0 ? r : a.compareTo(b);
      });
    final selRegion = f.regions.length == 1 ? f.regions.first : _allRegions;
    final selCountry = f.countries.isEmpty
        ? 'All'
        : (f.countries.length == 1
            ? f.countries.first
            : '${f.countries.length} countries');
    final level = f.levels.length == 1 ? f.levels.first : 'any';
    final field = f.fields.length == 1 ? f.fields.first : 'any';

    const coverageLabels = {
      'any': 'Any funding',
      'full': 'Full',
      'partial': 'Partial',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TfTabs(
          items: [_allRegions, ...regions],
          selected: selRegion,
          onSelected: (r) => onChanged(f.copyWith(
            regions: r == _allRegions ? <String>{} : <String>{r},
            countries: <String>{},
          )),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            AdPicker(
              label: 'Country',
              valueLabel: selCountry,
              onTap: () async {
                final r = await adPickCountry(context, countryCounts, f.countries);
                if (r == null) return;
                onChanged(f.copyWith(
                    countries: r.isEmpty ? <String>{} : <String>{r}));
              },
            ),
            if (showWithWays)
              TfSegmented(
                items: const ['All', 'With scholarships'],
                selected: f.withWaysOnly ? 'With scholarships' : 'All',
                onSelected: (v) =>
                    onChanged(f.copyWith(withWaysOnly: v == 'With scholarships')),
              ),
            if (showCoverage)
              TfSegmented(
                items: coverageLabels.values.toList(),
                selected: coverageLabels[f.coverage] ?? 'Any funding',
                onSelected: (v) => onChanged(f.copyWith(
                  coverage: coverageLabels.entries
                      .firstWhere((e) => e.value == v)
                      .key,
                )),
              ),
            if (showContent) ...[
              TfMenu(
                label: 'Level',
                valueLabel: level == 'any' ? 'Any' : level,
                value: level,
                options: {'any': 'Any', for (final l in kLevels) l: l},
                onSelected: (v) => onChanged(f.copyWith(
                    levels: v == 'any' ? <String>{} : <String>{v})),
              ),
              TfMenu(
                label: 'Field',
                valueLabel: field == 'any' ? 'Any' : field,
                value: field,
                options: {'any': 'Any', for (final k in kFields.keys) k: k},
                onSelected: (v) => onChanged(f.copyWith(
                    fields: v == 'any' ? <String>{} : <String>{v})),
              ),
            ],
            if (f.count > 0)
              TfTextAction(
                label: 'Clear filters',
                onPressed: () => onChanged(const AdFilters()),
              ),
          ],
        ),
      ],
    );
  }
}