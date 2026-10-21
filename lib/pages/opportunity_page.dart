// lib/pages/opportunity_page.dart
// One opportunity: headline, key facts, the main action, then the details as
// one calm reading column (no tabs to hunt through).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:tf_news/data/opportunity.dart';
import 'package:tf_news/pages/widgets.dart'
    show DateTone, OpportunityDateLabelX, formatOpportunityDate;
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:tf_news/utils/ui/tf_ui.dart' show tfToast;
import 'package:url_launcher/url_launcher.dart';

class _Sec {
  final String title;
  final String markdown;
  const _Sec(this.title, this.markdown);
}

class OpportunityPage extends StatefulWidget {
  const OpportunityPage({super.key});

  @override
  State<OpportunityPage> createState() => _OpportunityPageState();
}

class _OpportunityPageState extends State<OpportunityPage> {
  Future<Opportunity?>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final id = Get.parameters['id'];
    if (id != null && id.isNotEmpty) {
      _future = OpportunityRepository().getOpportunityById(id);
    }
  }

  Future<void> _openLink(String? href) async {
    if (href == null || href.isEmpty) return;
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: Uri.base.toString()));
    tfToast('Link copied', 'You can paste it anywhere to share this page.');
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _ymd(DateTime d) => '${d.year}${_two(d.month)}${_two(d.day)}';

  Future<void> _addToCalendar(Opportunity o) async {
    final dl = o.deadline;
    if (dl == null) return;
    final next = dl.add(const Duration(days: 1)); // all-day end is exclusive
    final url = 'https://calendar.google.com/calendar/render?action=TEMPLATE'
        '&text=${Uri.encodeComponent('Deadline: ${o.title}')}'
        '&dates=${_ymd(dl)}/${_ymd(next)}'
        '&details=${Uri.encodeComponent(o.link.isEmpty ? Uri.base.toString() : o.link)}';
    await _openLink(url);
  }

  List<_Sec> _sections(Opportunity o) => [
        _Sec('About', o.aboutMarkdown),
        _Sec('Requirements', o.requirementsMarkdown),
        _Sec('Benefits', o.benefitsMarkdown),
        _Sec('How to apply', o.guidelinesMarkdown),
      ].where((s) => s.markdown.trim().isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return _message('Opportunity not found',
        'The link is incomplete.');
    }

    return FutureBuilder<Opportunity?>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return TfPage(
            backLabel: 'Back',
            slivers: (c, l) => [
              l.gap(48),
              l.box(const TfRowSkeletons(count: 3)),
            ],
          );
        }
        if (snap.hasError) {
          debugPrint('Opportunity failed to load: ${snap.error}');
          return _message(
            'We could not load this',
            'Check your connection and try again.',
            actionLabel: 'Try again',
            onAction: () => setState(_load),
          );
        }
        final o = snap.data;
        if (o == null) {
          return _message('Opportunity not found',
              'It may have been removed, or the link is incomplete.');
        }
        return _content(o);
      },
    );
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

  Widget _content(Opportunity o) {
    final label = o.dateLabel(DateTime.now());
    final isOpen = label.isOpen;
    final urgent = label.tone == DateTone.urgent;
    final sections = _sections(o);
    final overline =
        [o.category, o.topic].where((s) => s.trim().isNotEmpty).join('  ·  ');
    final applyText = isOpen ? 'Apply now' : 'Visit official page';

    return TfPage(
      backLabel: 'Back',
      maxWidth: 900,
      bottomBar: (l) => (l.small && o.link.isNotEmpty)
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: tfHair, width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: TfPrimaryButton(
                  label: applyText,
                  icon: Icons.open_in_new,
                  expand: true,
                  onPressed: () => _openLink(o.link),
                ),
              ),
            )
          : null,
      slivers: (context, l) => [
        l.gap(l.small ? 28 : 48),
        l.box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(overline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: tfMuted, fontSize: 13)),
                ),
                if (o.mustKnow) ...[
                  const SizedBox(width: 10),
                  const Text('Must-know',
                      style: TextStyle(
                          color: tfUrgent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Semantics(
              header: true,
              child: Text(
                o.title,
                style: TextStyle(
                  color: tfInk,
                  fontWeight: FontWeight.w700,
                  height: 1.12,
                  letterSpacing: l.small ? -0.8 : -1.4,
                  fontSize: l.small ? 32 : 44,
                ),
              ),
            ),
            if (o.shortDescription.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(o.shortDescription,
                  style: const TextStyle(
                      color: tfMuted, fontSize: 18, height: 1.5)),
            ],
          ],
        )),
        l.gap(32),
        l.box(_facts(o, label.text, isOpen, urgent)),
        l.gap(20),
        l.box(Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (!l.small && o.link.isNotEmpty)
              TfPrimaryButton(
                label: applyText,
                icon: Icons.open_in_new,
                onPressed: () => _openLink(o.link),
              ),
            if (isOpen && o.deadline != null)
              TfTextAction(
                label: 'Add deadline to calendar',
                icon: Icons.edit_calendar_outlined,
                onPressed: () => _addToCalendar(o),
              ),
            TfTextAction(
              label: 'Copy link',
              icon: Icons.link,
              onPressed: _copyLink,
            ),
          ],
        )),
        l.gap(l.small ? 40 : 64),
        if (sections.isEmpty)
          l.box(const Text(
            'Details are coming soon. Use the official page for the latest information.',
            style: TextStyle(color: tfMuted, height: 1.5),
          ))
        else
          for (final s in sections) l.box(_section(context, s)),
      ],
    );
  }

  Widget _facts(Opportunity o, String dateText, bool isOpen, bool urgent) {
    Widget fact(String label, String value, {Color? color}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(color: tfMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color ?? tfInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w600)),
          ],
        );

    final start = o.startDate;
    final deadline = o.deadline;
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
          fact(isOpen ? 'Deadline' : 'Next opening', dateText,
              color: urgent ? tfUrgent : null),
          if (isOpen && deadline != null)
            fact('Closes on', formatOpportunityDate(deadline)),
          if (!isOpen && start != null)
            fact('Usually opens', formatOpportunityDate(start)),
          if (o.topic.isNotEmpty) fact('Field', o.topic),
          fact('Starred by',
              '${o.ratingCount} ${o.ratingCount == 1 ? 'student' : 'students'}'),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, _Sec s) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(s.title,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: tfInk,
                        letterSpacing: -0.6)),
              ),
              const SizedBox(height: 14),
              SelectionArea(
                child: MarkdownBody(
                  data: s.markdown,
                  onTapLink: (text, href, title) => _openLink(href),
                  styleSheet:
                      MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: const TextStyle(fontSize: 16, color: tfInk, height: 1.7),
                    listBullet:
                        const TextStyle(fontSize: 16, color: tfInk, height: 1.7),
                    h2: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: tfInk),
                    h3: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: tfInk),
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
}