// lib/pages/home_page.dart
// Home: quiet, typographic layout. One accent colour (the TF navy), no shadows,
// no per-section colours. Four equal section tiles, then two plain lists.
// One Firestore read feeds counts, search, closing-soon and must-know.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/data/opportunity.dart';
import 'package:tf_news/pages/widgets.dart';
import 'package:tf_news/utils/constants/colors.dart';
import 'package:tf_news/utils/ui/tf_ui.dart';

const Color _ink = Color(0xFF1D1D1F);
const Color _muted = Color(0xFF6E6E73);
const Color _tile = Color(0xFFF5F5F7);
const Color _hair = Color(0xFFD2D2D7);
const Color _accent = TColors.primary;

class _Feed {
  final List<Opportunity> all;
  final Map<String, int> counts;
  final List<Opportunity> closing;
  final List<Opportunity> mustKnow;
  const _Feed({
    this.all = const [],
    this.counts = const {},
    this.closing = const [],
    this.mustKnow = const [],
  });
}

Future<_Feed> _loadFeed() async {
  final snap =
      await FirebaseFirestore.instance.collection('opportunities').get();
  final now = DateTime.now();
  final all = <Opportunity>[];
  for (final doc in snap.docs) {
    try {
      all.add(Opportunity.fromFirestore(doc));
    } catch (e) {
      debugPrint('Skipping bad opportunity ${doc.id}: $e');
    }
  }
  final open = all.where((o) => o.isOpenAt(now)).toList();
  final counts = <String, int>{};
  for (final o in open) {
    counts[o.section] = (counts[o.section] ?? 0) + 1;
  }
  final closing = open.where((o) => o.deadline != null).toList()
    ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
  final must = open.where((o) => o.mustKnow).toList()
    ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
  return _Feed(
    all: all,
    counts: counts,
    closing: closing.take(6).toList(),
    mustKnow: must.take(5).toList(),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Read once per app session and reuse when the user comes back.
  static Future<_Feed>? _session;

  late Future<_Feed> _feed;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _feed = _session ??= _loadFeed();
    // A failed load must not stay cached for the whole session.
    _feed.catchError((Object e) {
      _session = null;
      return const _Feed();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _session = null;
      _feed = _session = _loadFeed();
    });
  }

  List<Opportunity> _matches(_Feed f) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return f.all
        .where((o) =>
            '${o.title} ${o.shortDescription} ${o.topic} ${o.category}'
                .toLowerCase()
                .contains(q))
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<_Feed>(
          future: _feed,
          builder: (context, snap) {
            final loading = snap.connectionState == ConnectionState.waiting;
            final failed = snap.hasError;
            final feed = snap.data ?? const _Feed();
            return LayoutBuilder(builder: (context, c) {
              final pad = tfSidePadding(c.maxWidth) + (c.maxWidth < 700 ? 0 : 8);
              final small = c.maxWidth < TfBreakpoints.mobile;
              final wide = c.maxWidth >= 820;
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(pad, 0, pad, 72),
                    children: [
                      _topBar(),
                      SizedBox(height: small ? 56 : 88),
                      _intro(small),
                      const SizedBox(height: 28),
                      _search(feed),
                      SizedBox(height: small ? 56 : 80),
                      _sectionGrid(small, loading, feed),
                      SizedBox(height: small ? 64 : 96),
                      if (failed)
                        _loadError()
                      else
                        _lists(context, wide, loading, feed),
                    ],
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  // -- top bar and intro ------------------------------------------------------

  Widget _topBar() {
    return Container(
      height: 64,
      alignment: Alignment.centerLeft,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hair, width: 0.5)),
      ),
      child: Row(
        children: [
          const Text(
            'TF News',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Obx(() {
            final name = UserController.instance.user.value.firstName.trim();
            if (name.isEmpty) return const SizedBox.shrink();
            return Text(name,
                style: const TextStyle(color: _muted, fontSize: 14));
          }),
        ],
      ),
    );
  }

  Widget _intro(bool small) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            'Opportunities,\nall in one place.',
            style: TextStyle(
              color: _ink,
              fontWeight: FontWeight.w700,
              height: 1.08,
              letterSpacing: small ? -1 : -2,
              fontSize:
                  (MediaQuery.sizeOf(context).width * 0.06).clamp(36.0, 64.0).toDouble(),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Scholarships, internships, programs and activities for students in Egypt.',
          style: TextStyle(color: _muted, fontSize: 18, height: 1.45),
        ),
      ],
    );
  }

  Widget _search(_Feed feed) {
    final results = _matches(feed);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 15, color: _ink),
            decoration: InputDecoration(
              hintText: 'Search opportunities',
              hintStyle: const TextStyle(color: _muted, fontSize: 15),
              prefixIcon: const Icon(Icons.search, size: 20, color: _muted),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 18, color: _muted),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: _tile,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
            ),
          ),
          if (_query.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            if (results.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Text('Nothing matches that yet.',
                    style: TextStyle(color: _muted)),
              )
            else
              for (final o in results) _Row(o: o, showCategory: true),
          ],
        ],
      ),
    );
  }

  // -- the four sections, equal weight ----------------------------------------

  Widget _sectionGrid(bool small, bool loading, _Feed feed) {
    final sections = OpportunitySection.all;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sections.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: small ? 1 : 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: tfScaledExtent(context, small ? 200 : 236),
      ),
      itemBuilder: (_, i) {
        final s = sections[i];
        final isStudy = s.id == OpportunitySection.study.id;
        final String? stat = isStudy
            ? '1,500+ universities'
            : (loading ? null : _statFor(feed.counts[s.id] ?? 0));
        return _SectionTile(
            section: s, stat: stat, loading: !isStudy && loading);
      },
    );
  }

  String _statFor(int n) => n == 0 ? 'Opening soon' : '$n open now';

  // -- closing soon and must-know ---------------------------------------------

  Widget _lists(BuildContext context, bool wide, bool loading, _Feed feed) {
    final closing = _listBlock(
      'Closing soon',
      loading
          ? [for (var i = 0; i < 4; i++) const _RowSkeleton()]
          : (feed.closing.isEmpty
              ? [const _Empty('No deadlines right now.')]
              : [for (final o in feed.closing) _Row(o: o)]),
    );
    final must = feed.mustKnow.isEmpty
        ? null
        : _listBlock('Must-know', [for (final o in feed.mustKnow) _Row(o: o)]);

    if (must == null) return closing;
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: closing),
          const SizedBox(width: 56),
          Expanded(child: must),
        ],
      );
    }
    return Column(children: [closing, const SizedBox(height: 56), must]);
  }

  Widget _listBlock(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -0.6,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1, thickness: 0.5, color: _hair),
        ...rows,
      ],
    );
  }

  Widget _loadError() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Live deadlines did not load. Check your connection.',
            style: TextStyle(color: _muted),
          ),
        ),
        TextButton(onPressed: _retry, child: const Text('Try again')),
      ],
    );
  }
}

/// One section, same tile for all four.
class _SectionTile extends StatelessWidget {
  final OpportunitySection section;
  final String? stat; // null = still loading or failed
  final bool loading;

  const _SectionTile({
    required this.section,
    required this.stat,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${section.title}. ${section.subtitle}',
      excludeSemantics: true,
      child: Material(
        color: _tile,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Get.toNamed(section.route),
          hoverColor: const Color(0x0A000000),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  section.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: _muted, fontSize: 15, height: 1.45),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (stat != null)
                      Flexible(
                        child: Text(stat!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _muted, fontSize: 13)),
                      )
                    else if (loading)
                      const Pulse(child: SkeletonBox(width: 80, height: 12)),
                    const Spacer(),
                    const Text('Explore',
                        style: TextStyle(
                            color: _accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right, color: _accent, size: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A plain list row: title on the left, date on the right, hairline below.
class _Row extends StatelessWidget {
  final Opportunity o;
  final bool showCategory;
  const _Row({required this.o, this.showCategory = false});

  @override
  Widget build(BuildContext context) {
    final label = o.dateLabel(DateTime.now());
    final urgent = label.tone == DateTone.urgent;
    return Column(
      children: [
        InkWell(
          onTap: () => Get.toNamed('/opportunity/${o.id}'),
          hoverColor: const Color(0x08000000),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (o.category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(o.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: _muted, fontSize: 12)),
                        ),
                      Text(
                        o.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  label.text,
                  style: TextStyle(
                    color: urgent ? kBad : _muted,
                    fontSize: 13,
                    fontWeight: urgent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: _hair),
      ],
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Pulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 70, height: 10),
            SizedBox(height: 8),
            SkeletonBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(text, style: const TextStyle(color: _muted)),
    );
  }
}