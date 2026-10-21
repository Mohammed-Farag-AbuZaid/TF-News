// lib/authentication/admissions_programs.dart
// "Program" = a scholarship that is NOT the university itself (external_program),
// grouped by provider across every university it applies to.
// Also: region normalisation (MENA, Sub-Saharan Africa, ...) and level/field detection.
import 'package:tf_news/authentication/admissions_models.dart';

// ---------------------------------------------------------------------------
// Regions
// ---------------------------------------------------------------------------

const List<String> kRegionOrder = [
  'MENA',
  'Europe',
  'Sub-Saharan Africa',
  'Asia',
  'North America',
  'Latin America',
  'Oceania',
];

const Set<String> _menaCountries = {
  'egypt', 'algeria', 'bahrain', 'iran', 'iraq', 'israel', 'jordan', 'kuwait',
  'lebanon', 'libya', 'morocco', 'oman', 'palestine', 'qatar', 'saudi arabia',
  'syria', 'tunisia', 'turkey', 'türkiye', 'turkiye', 'united arab emirates',
  'yemen',
};

/// The region shown in the UI. The data has Africa / Americas as single
/// regions, so we split them into MENA / Sub-Saharan Africa / North / Latin America.
String adRegionOf(University u) {
  final c = u.country.trim().toLowerCase();
  final r = u.region.trim().toLowerCase();
  if (_menaCountries.contains(c)) return 'MENA';
  if (r == 'africa') return 'Sub-Saharan Africa';
  if (r == 'americas') {
    return (c.contains('united states') || c == 'canada')
        ? 'North America'
        : 'Latin America';
  }
  if (r.isEmpty) return 'Other';
  return u.region.trim();
}

int adRegionIndex(String r) {
  final i = kRegionOrder.indexOf(r);
  return i == -1 ? 999 : i;
}

// ---------------------------------------------------------------------------
// Level / field detection (from the official text we already store)
// ---------------------------------------------------------------------------

const List<String> kLevels = ['Bachelor', 'Master', 'PhD'];

const Map<String, List<String>> kFields = {
  'Engineering & Tech': [
    'engineering', 'computer science', 'informatics', 'artificial intelligence',
    'data science', 'software',
  ],
  'Medicine & Health': ['medicine', 'medical', 'nursing', 'pharmacy', 'dentist', 'public health'],
  'Business & Economics': ['business', 'economics', 'finance', 'mba', 'entrepreneur'],
  'Natural Sciences': ['physics', 'chemistry', 'biology', 'mathematics', 'natural science', 'life science'],
  'Social Sciences & Law': ['law', 'politics', 'social science', 'public policy', 'international relations'],
  'Arts & Humanities': ['arts', 'humanities', 'history', 'literature', 'linguistics', 'architecture', 'design'],
};

final Map<String, RegExp> _fieldRx = {
  for (final e in kFields.entries)
    e.key: RegExp('\\b(?:${e.value.join('|')})', caseSensitive: false),
};
final RegExp _bachelorRx =
    RegExp(r'bachelor|undergraduate|\bb\.?sc\b', caseSensitive: false);
final RegExp _masterRx =
    RegExp(r"\bmaster|postgraduate|\bm\.?sc\b", caseSensitive: false);
final RegExp _phdRx = RegExp(r'\bph\.?d\b|doctora', caseSensitive: false);

String _detectText(ScholarshipWay w) {
  final p = parseWayMarkdown(w.markdown);
  return '${w.title} ${p.sections['Overview'] ?? ''} ${p.sections['Requirements'] ?? ''}';
}

// ---------------------------------------------------------------------------
// Program model
// ---------------------------------------------------------------------------

class ProgramEntry {
  final University uni;
  final ScholarshipWay way;
  const ProgramEntry(this.uni, this.way);
}

String adSlug(String s) => s
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

class Program {
  final String key;
  final String name;
  final List<ProgramEntry> entries; // best-ranked university first
  final Set<String> levels; // empty = not stated (matches any level filter)
  final Set<String> fields; // empty = not stated (matches any field filter)

  Program({
    required this.key,
    required this.name,
    required this.entries,
    required this.levels,
    required this.fields,
  });

  int get uniCount => entries.length;

  String get coverage {
    if (entries.any((e) => e.way.coverage == 'full')) return 'full';
    if (entries.any((e) => e.way.coverage == 'partial')) return 'partial';
    return 'unknown';
  }

  late final Set<String> regions = {for (final e in entries) adRegionOf(e.uni)};
  late final Set<String> countries = {for (final e in entries) e.uni.country};

  late final String searchText = [
    name,
    ...entries.map((e) => e.way.title),
    ...entries.map((e) => e.uni.name),
    ...countries,
  ].join(' ').toLowerCase();

  bool matchesLevels(Set<String> sel) =>
      sel.isEmpty || levels.isEmpty || levels.any(sel.contains);
  bool matchesFields(Set<String> sel) =>
      sel.isEmpty || fields.isEmpty || fields.any(sel.contains);
}

List<Program> buildPrograms(List<University> unis, List<ScholarshipWay> ways) {
  final byId = {for (final u in unis) u.uniId: u};
  final groups = <String, List<ProgramEntry>>{};
  final names = <String, String>{};

  for (final w in ways) {
    if (!w.isExternal) continue;
    final u = byId[w.uniId];
    if (u == null) continue;
    final name = w.provider.trim().isNotEmpty ? w.provider.trim() : w.title.trim();
    if (name.isEmpty) continue;
    final key = adSlug(name);
    if (key.isEmpty) continue;
    names.putIfAbsent(key, () => name);
    final list = groups.putIfAbsent(key, () => <ProgramEntry>[]);
    if (list.any((e) => e.uni.uniId == u.uniId && e.way.wayNo == w.wayNo)) continue;
    list.add(ProgramEntry(u, w));
  }

  final out = <Program>[];
  for (final g in groups.entries) {
    final entries = g.value
      ..sort((a, b) =>
          (a.uni.qsRank ?? 99999).compareTo(b.uni.qsRank ?? 99999));
    final levels = <String>{};
    final fields = <String>{};
    for (final e in entries) {
      final t = _detectText(e.way);
      if (_bachelorRx.hasMatch(t)) levels.add('Bachelor');
      if (_masterRx.hasMatch(t)) levels.add('Master');
      if (_phdRx.hasMatch(t)) levels.add('PhD');
      for (final f in _fieldRx.entries) {
        if (f.value.hasMatch(t)) fields.add(f.key);
      }
    }
    out.add(Program(
      key: g.key,
      name: names[g.key]!,
      entries: entries,
      levels: levels,
      fields: fields,
    ));
  }
  out.sort((a, b) => b.uniCount.compareTo(a.uniCount));
  return out;
}