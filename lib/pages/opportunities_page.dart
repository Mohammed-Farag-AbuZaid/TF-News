// lib/pages/opportunities_page.dart
// One section (Activities, Internships, Programs): category tabs, a few quiet
// controls, then a plain list. Same layout on phone and desktop.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/data/opportunity.dart';
import 'package:tf_news/pages/widgets.dart'
    show DateTone, OpportunityDateLabelX;
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:tf_news/utils/ui/tf_ui.dart' show tfToast;

class OpportunitiesPage extends StatefulWidget {
  final OpportunitySection section;
  final String initialCategory;
  const OpportunitiesPage({
    super.key,
    required this.section,
    this.initialCategory = 'All',
  });

  @override
  State<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends State<OpportunitiesPage> {
  static const String _openNow = 'Open now';
  static const String _openingSoon = 'Opening soon';
  static const Map<String, String> _sorts = {
    'soonest': 'Soonest deadline',
    'popular': 'Most starred',
    'az': 'A to Z',
  };

  final OpportunityRepository _repository = OpportunityRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  String? _category; // null = All
  String? _topic; // null = all topics
  String _status = _openNow;
  String _query = '';
  String _sort = 'soonest';
  late Future<List<Opportunity>> _future;

  OpportunityStatus get _statusEnum => _status == _openingSoon
      ? OpportunityStatus.upcoming
      : OpportunityStatus.open;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory == 'All' ? null : widget.initialCategory;
    _future = _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Opportunity>> _fetch() {
    final mustKnow = _category == OpportunitySection.mustKnow;
    return _repository.getOpportunities(
      section: widget.section.id,
      category: mustKnow ? null : _category,
      topic: _topic,
      mustKnow: mustKnow ? true : null,
    );
  }

  void _refetch() {
    setState(() {
      _future = _fetch();
    });
  }

  void _pickCategory(String c) {
    _category = c == 'All' ? null : c;
    _topic = null; // topics depend on the tab
    _refetch();
  }

  void _pickTopic(String t) {
    _topic = t == OpportunitySection.allTopics ? null : t;
    _refetch();
  }

  void _clearFilters() {
    _searchCtrl.clear();
    _query = '';
    _topic = null;
    _refetch();
  }

  List<Opportunity> _apply(List<Opportunity> all) {
    var list = all.forStatus(_statusEnum);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((o) =>
              '${o.title} ${o.shortDescription} ${o.topic} ${o.category}'
                  .toLowerCase()
                  .contains(q))
          .toList();
    }
    if (_sort == 'popular') {
      list = List<Opportunity>.of(list)
        ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
    } else if (_sort == 'az') {
      list = List<Opportunity>.of(list)
        ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final topics = s.topicsFor(_category);
    return TfPage(
      backLabel: 'Home',
      slivers: (context, l) => [
        l.gap(l.small ? 28 : 48),
        l.box(TfTitle(title: s.title, subtitle: s.subtitle, small: l.small)),
        l.gap(24),
        l.box(TfTabs(
          items: s.categories,
          selected: _category ?? 'All',
          onSelected: _pickCategory,
        )),
        l.gap(16),
        l.box(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: TfSearch(
                controller: _searchCtrl,
                hint: 'Search ${s.title.toLowerCase()}',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                TfSegmented(
                  items: const [_openNow, _openingSoon],
                  selected: _status,
                  onSelected: (v) => setState(() => _status = v),
                ),
                TfMenu(
                  label: s.topicsLabel,
                  valueLabel: _topic ?? 'All',
                  value: _topic ?? OpportunitySection.allTopics,
                  options: {for (final t in topics) t: t},
                  onSelected: _pickTopic,
                ),
                TfMenu(
                  label: 'Sort',
                  valueLabel: _sorts[_sort]!,
                  value: _sort,
                  options: _sorts,
                  onSelected: (v) => setState(() => _sort = v),
                ),
              ],
            ),
          ],
        )),
        l.gap(20),
        FutureBuilder<List<Opportunity>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return l.box(const TfRowSkeletons());
            }
            if (snap.hasError) {
              debugPrint('Opportunities failed to load: ${snap.error}');
              return l.box(TfEmpty(
                title: 'We could not load this',
                message: 'Check your connection and try again.',
                actionLabel: 'Try again',
                onAction: _refetch,
              ));
            }
            final list = _apply(snap.data ?? const []);
            if (list.isEmpty) return l.box(_empty());
            return SliverMainAxisGroup(
              slivers: [
                l.box(Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${list.length} ${list.length == 1 ? 'opportunity' : 'opportunities'}',
                    style: const TextStyle(color: tfMuted, fontSize: 13),
                  ),
                )),
                l.box(const Divider(height: 1, thickness: 0.5, color: tfHair)),
                l.rows(
                  list.length,
                  (_, i) => _OppRow(key: ValueKey(list[i].id), o: list[i]),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _empty() {
    if (_query.trim().isNotEmpty || _topic != null) {
      return TfEmpty(
        title: 'Nothing matches',
        message: 'Try a different word, or clear the filters.',
        actionLabel: 'Clear filters',
        onAction: _clearFilters,
      );
    }
    if (_statusEnum == OpportunityStatus.open) {
      return TfEmpty(
        title: 'Nothing is open right now',
        message: 'See what is opening soon so you can prepare early.',
        actionLabel: 'Show opening soon',
        onAction: () => setState(() => _status = _openingSoon),
      );
    }
    return const TfEmpty(
      title: 'No opportunities yet',
      message: 'New ones are added regularly. Check back soon.',
    );
  }
}

/// One opportunity: overline, title, two lines of description, date and star.
class _OppRow extends StatefulWidget {
  final Opportunity o;
  const _OppRow({super.key, required this.o});

  @override
  State<_OppRow> createState() => _OppRowState();
}

class _OppRowState extends State<_OppRow> {
  late bool _voted;
  late int _count;
  bool _busy = false;

  String get _uid => UserController.instance.user.value.id;

  @override
  void initState() {
    super.initState();
    _count = widget.o.ratingCount;
    _voted = widget.o.voters.contains(_uid);
  }

  Future<void> _toggle() async {
    if (_busy) return;
    final uid = _uid;
    if (uid.isEmpty) {
      tfToast('Sign in needed', 'Please sign in to star opportunities.');
      return;
    }
    setState(() => _busy = true);
    final ref =
        FirebaseFirestore.instance.collection('opportunities').doc(widget.o.id);
    try {
      if (_voted) {
        await ref.update({
          'ratingCount': FieldValue.increment(-1),
          'voters': FieldValue.arrayRemove([uid]),
        });
        if (!mounted) return;
        setState(() {
          _voted = false;
          _count--;
        });
      } else {
        await ref.update({
          'ratingCount': FieldValue.increment(1),
          'voters': FieldValue.arrayUnion([uid]),
        });
        if (!mounted) return;
        setState(() {
          _voted = true;
          _count++;
        });
      }
    } catch (_) {
      tfToast('Something went wrong', 'Could not register your star. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final label = o.dateLabel(DateTime.now());
    final urgent = label.tone == DateTone.urgent;
    final overline =
        [o.category, o.topic].where((s) => s.trim().isNotEmpty).join('  ·  ');

    return Column(
      children: [
        InkWell(
          onTap: () => Get.toNamed('/opportunity/${o.id}'),
          hoverColor: const Color(0x08000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline.isNotEmpty)
                  Text(overline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: tfMuted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  o.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: tfInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    letterSpacing: -0.2,
                  ),
                ),
                if (o.shortDescription.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    o.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: tfMuted, fontSize: 14, height: 1.5),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label.text,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: urgent ? tfUrgent : tfMuted,
                          fontSize: 13,
                          fontWeight: urgent ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ),
                    if (o.mustKnow) ...[
                      const SizedBox(width: 10),
                      const Text('Must-know',
                          style: TextStyle(
                              color: tfUrgent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                    const Spacer(),
                    Semantics(
                      button: true,
                      label: _voted
                          ? 'Remove your star, $_count stars'
                          : 'Star this opportunity, $_count stars',
                      excludeSemantics: true,
                      child: InkWell(
                        onTap: _toggle,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _busy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 1.5, color: tfMuted),
                                    )
                                  : Icon(
                                      _voted
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 20,
                                      color: _voted ? tfInk : tfMuted,
                                    ),
                              const SizedBox(width: 4),
                              Text('$_count',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _voted ? tfInk : tfMuted)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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