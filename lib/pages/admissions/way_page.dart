// lib/pages/admissions/way_page.dart
// One scholarship way: header, the official passages in reading order, the
// sources, and the next / previous scholarship at this university.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/admissions_models.dart';
import 'package:tf_news/authentication/admissions_repository.dart';
import 'package:tf_news/pages/admissions/ad_kit.dart';
import 'package:tf_news/pages/admissions/university_page.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:tf_news/utils/ui/tf_ui.dart' show tfToast;

/// One quoted passage and the page it was copied from.
class _Passage {
  final String quote;
  final String? url;
  const _Passage(this.quote, this.url);
}

/// Splits a section into passages: the quote lines, ended by "Source: url".
List<_Passage> _parsePassages(String md) {
  final out = <_Passage>[];
  final buf = <String>[];
  void flush(String? url) {
    if (buf.isEmpty) return;
    out.add(_Passage(buf.join('\n'), url));
    buf.clear();
  }

  final source = RegExp(r'^Source:\s*(https?://\S+)\s*$');
  for (final raw in md.split('\n')) {
    final line = raw.trimRight();
    final m = source.firstMatch(line.trim());
    if (m != null) {
      flush(m.group(1));
    } else if (line.trim().isNotEmpty) {
      buf.add(line);
    }
  }
  flush(null);
  return out;
}

String _host(String url) {
  final m = RegExp(r'^https?://(?:www\.)?([^/?#\s]+)', caseSensitive: false)
      .firstMatch(url);
  return m?.group(1) ?? url;
}

class WayPage extends StatefulWidget {
  const WayPage({super.key});

  @override
  State<WayPage> createState() => _WayPageState();
}

class _WayPageState extends State<WayPage> {
  int? _uniId;
  int? _wayNo;
  Future<List<Object?>>? _future;

  @override
  void initState() {
    super.initState();
    _uniId = int.tryParse(Get.parameters['id'] ?? '');
    _wayNo = int.tryParse(Get.parameters['way'] ?? '');
    _load();
  }

  void _load() {
    final id = _uniId;
    if (id == null || _wayNo == null) return;
    final repo = AdmissionsRepository();
    _future = Future.wait<Object?>([repo.getUniversity(id), repo.getWays(id)]);
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: Uri.base.toString()));
    tfToast('Link copied', 'You can paste it anywhere to share this page.');
  }

  Widget _message(String title, String message,
      {String? actionLabel, VoidCallback? onAction}) {
    return TfPage(
      backLabel: 'Back',
      slivers: (c, l) => [
        l.box(TfEmpty(
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        )),
      ],
    );
  }

  Widget _notFound() => _message(
        'Scholarship not found',
        'The link may be incomplete, or the scholarship was removed.',
        actionLabel: 'See all universities',
        onAction: () => Get.offAllNamed('/study/universities'),
      );

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) return _notFound();

    return FutureBuilder<List<Object?>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return TfPage(
            backLabel: 'Back',
            slivers: (c, l) => [l.gap(48), l.box(const TfRowSkeletons(count: 3))],
          );
        }
        if (snap.hasError) {
          debugPrint('Scholarship failed to load: ${snap.error}');
          return _message(
            'We could not load this',
            'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => setState(_load),
          );
        }
        final uni = snap.data![0] as University?;
        final ways = sortWays(snap.data![1] as List<ScholarshipWay>);
        final index = ways.indexWhere((w) => w.wayNo == _wayNo);
        if (uni == null || index < 0) return _notFound();
        return _content(uni, ways, index);
      },
    );
  }

  Widget _content(University uni, List<ScholarshipWay> ways, int index) {
    final way = ways[index];
    final prev = index > 0 ? ways[index - 1] : null;
    final next = index + 1 < ways.length ? ways[index + 1] : null;
    final parsed = parseWayMarkdown(way.markdown);
    final applyUrl = parsed.applyUrl ??
        (way.sourceUrls.isNotEmpty ? way.sourceUrls.first : null);
    // Each passage gets a small numbered marker like [1] instead of a long
    // "Source: url" line; the numbered list of sources appears once at the end.
    // A passage that appears under two headings is shown only once.
    final seen = <String>{};
    final urlIndex = <String, int>{};
    final secs = <MapEntry<String, String>>[];
    for (final e in parsed.sections.entries) {
      final parts = <String>[];
      for (final p in _parsePassages(e.value)) {
        final key =
            p.quote.replaceAll(RegExp(r'[>\s]+'), ' ').trim().toLowerCase();
        if (key.isEmpty || !seen.add(key)) continue;
        var q = p.quote;
        final url = p.url;
        if (url != null) {
          final n = urlIndex.putIfAbsent(url, () => urlIndex.length + 1);
          q = '$q [$n]($url)';
        }
        parts.add(q);
      }
      if (parts.isNotEmpty) secs.add(MapEntry(e.key, parts.join('\n\n')));
    }
    for (final u in way.sourceUrls) {
      urlIndex.putIfAbsent(u, () => urlIndex.length + 1);
    }
    final sourcesMd = urlIndex.entries
        .map((e) => '${e.value}. [${_host(e.key)}](${e.key})')
        .join('\n');
    final sourceCount = urlIndex.length;

    return TfPage(
      backLabel: uni.name,
      maxWidth: 900,
      bottomBar: (l) => (l.small && applyUrl != null)
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: tfHair, width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: TfPrimaryButton(
                  label: 'Open the official page',
                  icon: Icons.open_in_new,
                  expand: true,
                  onPressed: () => openExternalLink(applyUrl),
                ),
              ),
            )
          : null,
      slivers: (context, l) => [
        l.gap(l.small ? 28 : 48),
        l.box(Row(
          children: [
            CoverageBadge(coverage: way.coverage),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                way.isExternal ? 'External program' : "University's own",
                style: const TextStyle(color: tfMuted, fontSize: 13),
              ),
            ),
          ],
        )),
        l.gap(10),
        l.box(Semantics(
          header: true,
          child: Text(
            way.title,
            style: TextStyle(
              color: tfInk,
              fontWeight: FontWeight.w700,
              height: 1.12,
              letterSpacing: l.small ? -0.8 : -1.4,
              fontSize: l.small ? 30 : 42,
            ),
          ),
        )),
        if (way.provider.isNotEmpty || way.isExternal) ...[
          l.gap(12),
          l.box(Text(
            [
              if (way.provider.isNotEmpty) 'By ${way.provider}',
              if (way.isExternal) 'May cover other universities too',
            ].join('  ·  '),
            style: const TextStyle(color: tfMuted, fontSize: 17, height: 1.45),
          )),
        ],
        l.gap(24),
        l.box(Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!l.small && applyUrl != null)
              TfPrimaryButton(
                label: 'Official page',
                icon: Icons.open_in_new,
                onPressed: () => openExternalLink(applyUrl),
              ),
            TfTextAction(label: 'Copy link', icon: Icons.link, onPressed: _copyLink),
          ],
        )),
        l.gap(20),
        l.box(AdNote(sourceCount > 0
            ? 'Every passage below is copied word for word from an official page ($sourceCount ${sourceCount == 1 ? 'source' : 'sources'}) with its link. Always confirm dates on the official site.'
            : 'Always confirm dates on the official site.')),
        l.gap(l.small ? 36 : 52),
        if (secs.isEmpty)
          l.box(const Text(
            'No details available yet. Use the official page for the latest information.',
            style: TextStyle(color: tfMuted, height: 1.5),
          ))
        else
          for (final e in secs) l.box(_section(context, e.key, e.value)),
        if (sourceCount > 0) l.box(_section(context, 'Sources', sourcesMd)),
        if (prev != null || next != null) ...[
          l.gap(8),
          l.box(const Divider(height: 1, thickness: 0.5, color: tfHair)),
          if (prev != null)
            l.box(_navRow(uni, prev, 'Previous scholarship', Icons.arrow_back)),
          if (next != null)
            l.box(_navRow(uni, next, 'Next scholarship', Icons.arrow_forward)),
        ],
      ],
    );
  }

  Widget _section(BuildContext context, String title, String markdown) {
    if (markdown.trim().isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdSectionTitle(title),
              const SizedBox(height: 14),
              SelectionArea(
                child: MarkdownBody(
                  data: markdown,
                  onTapLink: (text, href, t) => openExternalLink(href),
                  styleSheet:
                      MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: const TextStyle(fontSize: 16, color: tfInk, height: 1.7),
                    listBullet:
                        const TextStyle(fontSize: 16, color: tfInk, height: 1.7),
                    blockquote:
                        const TextStyle(fontSize: 16, color: tfInk, height: 1.7),
                    blockquoteDecoration: BoxDecoration(
                      color: tfTile,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    blockquotePadding: const EdgeInsets.all(16),
                    a: const TextStyle(
                        color: tfAccent, decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navRow(University uni, ScholarshipWay w, String label, IconData icon) {
    return Column(
      children: [
        InkWell(
          // offNamed keeps "back" going to the university, not through every way
          onTap: () =>
              Get.offNamed('/admissions/university/${uni.uniId}/way/${w.wayNo}'),
          hoverColor: const Color(0x08000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 2),
            child: Row(
              children: [
                Icon(icon, size: 18, color: tfMuted),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(color: tfMuted, fontSize: 12)),
                      const SizedBox(height: 3),
                      Text(w.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: tfInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: tfHair),
      ],
    );
  }
}