// lib/data/admissions_models.dart
// Models for the Admissions & Scholarships section.

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

String _str(dynamic v) => v == null ? '' : v.toString();

class University {
  final int uniId;
  final String name;
  final String country;
  final String region;
  final int? qsRank; // start of the QS band, e.g. 781 for "781-790"
  final String qsRankText; // as published, e.g. "781-790" or "1401+"
  final String website;
  final bool researched;
  final int waysFound;

  const University({
    required this.uniId,
    required this.name,
    required this.country,
    required this.region,
    required this.qsRank,
    required this.qsRankText,
    required this.website,
    required this.researched,
    required this.waysFound,
  });

  bool get isEgypt => country.trim().toLowerCase() == 'egypt';

  /// Host only, e.g. "mit.edu" (for display).
  String get websiteHost {
    final m = RegExp(r'^(?:https?://)?(?:www\.)?([^/:?#\s]+)', caseSensitive: false)
        .firstMatch(website.trim());
    return m?.group(1) ?? '';
  }

  factory University.fromJson(Map<String, dynamic> j) => University(
        uniId: _toInt(j['uni_id']) ?? 0,
        name: _str(j['name']),
        country: _str(j['country']),
        region: _str(j['region']),
        qsRank: _toInt(j['qs_rank']),
        qsRankText: _str(j['qs_rank_text']),
        website: _str(j['website']),
        researched: _str(j['researched']) == 'yes',
        waysFound: _toInt(j['ways_found']) ?? 0,
      );
}

class ScholarshipWay {
  final int uniId;
  final int wayNo;
  final String title;
  final String provider;
  final String scope; // 'university' | 'external_program'
  final String coverage; // 'full' | 'partial' | 'unknown'
  final String markdown;
  final List<String> sourceUrls;

  const ScholarshipWay({
    required this.uniId,
    required this.wayNo,
    required this.title,
    required this.provider,
    required this.scope,
    required this.coverage,
    required this.markdown,
    required this.sourceUrls,
  });

  bool get isExternal => scope == 'external_program';

  factory ScholarshipWay.fromJson(Map<String, dynamic> j) => ScholarshipWay(
        uniId: _toInt(j['uni_id']) ?? 0,
        wayNo: _toInt(j['way_no']) ?? 0,
        title: _str(j['title']),
        provider: _str(j['provider']),
        scope: _str(j['scope']),
        coverage: _str(j['coverage']),
        markdown: _str(j['markdown']),
        sourceUrls: _str(j['source_urls'])
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
}

/// A way's markdown split into its "## " sections.
class ParsedWay {
  final String intro; // lines before the first "## " (provider / coverage)
  final Map<String, String> sections; // insertion-ordered

  const ParsedWay(this.intro, this.sections);

  /// First http(s) link found in the "Apply link" section, if any.
  String? get applyUrl {
    final text = sections['Apply link'];
    if (text == null) return null;
    final m = RegExp(r'https?://[^\s)>\]]+').firstMatch(text);
    return m?.group(0);
  }
}

ParsedWay parseWayMarkdown(String md) {
  final intro = StringBuffer();
  final sections = <String, StringBuffer>{};
  String? current;
  for (final line in md.split('\n')) {
    if (line.startsWith('# ')) continue; // title is shown separately
    if (line.startsWith('## ')) {
      current = line.substring(3).trim();
      sections[current] = StringBuffer();
      continue;
    }
    if (current == null) {
      intro.writeln(line);
    } else {
      sections[current]!.writeln(line);
    }
  }
  return ParsedWay(
    intro.toString().trim(),
    {for (final e in sections.entries) e.key: e.value.toString().trim()},
  );
}

/// Makes "Source: https://..." lines clickable in the markdown view.
String linkifySources(String md) => md.replaceAllMapped(
      RegExp(r'^Source:\s*(https?://\S+)\s*$', multiLine: true),
      (m) => 'Source: [${m.group(1)}](${m.group(1)})',
    );


/// Best funding first: full, then partial, then anything else; ties keep research order.
List<ScholarshipWay> sortWays(List<ScholarshipWay> ways) {
  int rank(String c) => c == 'full' ? 0 : (c == 'partial' ? 1 : 2);
  final list = List<ScholarshipWay>.of(ways);
  list.sort((a, b) {
    final r = rank(a.coverage).compareTo(rank(b.coverage));
    return r != 0 ? r : a.wayNo.compareTo(b.wayNo);
  });
  return list;
}