// lib/pages/home_page.dart
// Home — TF Oxford & Stone editorial observatory for TF News (news.tfunions.com).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/data/opportunity.dart';
import 'package:tf_news/pages/widgets.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';
import 'package:tf_news/utils/ui/tf_ui.dart'
    show tfSidePadding, TfBreakpoints, Pulse, SkeletonBox;

// ---------------------------------------------------------------------------
// Data bundle
// ---------------------------------------------------------------------------

class _Feed {
  final Map<String, int> bySection;
  final List<Opportunity> allOpen;
  final List<Opportunity> closing;
  final List<Opportunity> mustKnow;
  final List<Opportunity> all;

  const _Feed({
    this.bySection = const {},
    this.allOpen = const [],
    this.closing = const [],
    this.mustKnow = const [],
    this.all = const [],
  });
}

Future<_Feed> _loadFeed() async {
  final all = await OpportunityRepository().fetchAllOpportunities(
    forceRefresh: true,
  );
  final now = DateTime.now();
  final open = all.where((o) => o.isOpenAt(now)).toList();

  final counts = <String, int>{};
  for (final o in open) {
    counts[o.section] = (counts[o.section] ?? 0) + 1;
  }

  final closing = open.where((o) => o.deadline != null).toList()
    ..sort((a, b) => a.deadline!.compareTo(b.deadline!));

  final must = open.where((o) => o.mustKnow).toList()
    ..sort((a, b) => b.ratingCount.compareTo(a.ratingCount));

  final sortedOpen = List<Opportunity>.from(open)
    ..sort((a, b) {
      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      }
      if (a.deadline != null) return -1;
      if (b.deadline != null) return 1;
      return b.ratingCount.compareTo(a.ratingCount);
    });

  return _Feed(
    bySection: counts,
    allOpen: sortedOpen.take(10).toList(),
    closing: closing.take(8).toList(),
    mustKnow: must.take(8).toList(),
    all: all,
  );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<_Feed>? _future;
  _Feed _feed = const _Feed();
  bool _loading = true;
  Object? _error;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _bulletinTab = 'All Open';

  @override
  void initState() {
    super.initState();
    _retry();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    final f = _loadFeed();
    _future = f;
    f.then((feed) {
      if (!mounted || _future != f) return;
      setState(() {
        _feed = feed;
        _loading = false;
      });
    }).catchError((Object e) {
      if (!mounted || _future != f) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    });
  }

  List<Opportunity> _matches() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _feed.all.where((o) {
      return o.title.toLowerCase().contains(q) ||
          o.shortDescription.toLowerCase().contains(q) ||
          o.category.toLowerCase().contains(q) ||
          o.topic.toLowerCase().contains(q) ||
          o.section.toLowerCase().contains(q);
    }).toList();
  }

  List<Opportunity> _activeBulletins() {
    switch (_bulletinTab) {
      case 'Closing Soon':
        return _feed.closing;
      case 'Must-Know':
        return _feed.mustKnow;
      default:
        return _feed.allOpen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches();
    return Scaffold(
      backgroundColor: tfCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final pad = tfSidePadding(c.maxWidth) + (c.maxWidth < 700 ? 0 : 8);
            final small = c.maxWidth < TfBreakpoints.mobile;
            final wide = c.maxWidth >= 880;
            return CustomScrollView(
              slivers: [
                // ── Top Masthead + Hero Observatory (Full-bleed Oxford Navy) ─
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: tfNavy,
                      border: Border(
                        bottom: BorderSide(color: tfNavyLine, width: 1),
                      ),
                    ),
                    child: Column(
                      children: [
                        _mastheadBar(pad, small),
                        const Divider(height: 1, thickness: 1, color: tfNavyLine),
                        _heroStage(pad, small, wide),
                      ],
                    ),
                  ),
                ),

                // ── Warm Architectural Stone Content Canvas ─────────────────
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(pad, small ? 24 : 36, pad, 64),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_query.trim().isNotEmpty)
                              _searchResultsPanel(matches)
                            else ...[
                              _admissionsShowcase(small, wide),
                              const SizedBox(height: 24),
                              _divisionRow(small, wide),
                              const SizedBox(height: 32),
                              _bulletinsPanel(small, wide),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Full-width Masthead ────────────────────────────────────────────────────

  Widget _mastheadBar(double pad, bool small) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad, vertical: 14),
          child: Row(
            children: [
              // Brand crest
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tfNavyAlt,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: tfGold, width: 1.5),
                    ),
                    child: const Text(
                      'TF',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TF News',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
              if (!small) ...[
                const SizedBox(width: 22),
                _navChip('Admissions', '/study'),
                const SizedBox(width: 6),
                _navChip('Universities', '/study/universities'),
                const SizedBox(width: 6),
                _navChip('Programs', '/study/programs'),
                const SizedBox(width: 6),
                _navChip('Activities', '/activities'),
              ],
              const Spacer(),
              Obx(() {
                final name = UserController.instance.user.value.firstName.trim();
                if (name.isEmpty) {
                  return InkWell(
                    onTap: () => Get.toNamed('/study'),
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: tfAccent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: const Color(0xFF2853B8)),
                      ),
                      child: const Text(
                        'Explore Index',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: tfNavyAlt,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: tfNavyLine),
                  ),
                  child: Text(
                    'Scholar · $name',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navChip(String label, String route) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFFD6DCE8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── Split Hero Command Stage ───────────────────────────────────────────────

  Widget _heroStage(double pad, bool small, bool wide) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 36, height: 3, color: tfGold),
        const SizedBox(height: 16),
        Text(
          'Opportunities & Admissions Bulletin',
          style: TextStyle(
            fontSize: small ? 13 : 13.5,
            fontWeight: FontWeight.w700,
            color: tfGold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scholarships, university admissions, and verified pathways.',
          style: TextStyle(
            fontSize: small ? 28 : 40,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -1.1,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Compare 1,500+ international admission routes, track closing scholarship deadlines, and browse vetted research, internship, and extracurricular programs across Egypt.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFFD6DCE8),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        // High-contrast crisp white search input inside dark masthead
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(
            fontSize: 14.5,
            color: tfInk,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search scholarships, universities, internships, programs...',
            hintStyle: const TextStyle(fontSize: 14, color: tfMuted),
            prefixIcon: const Icon(Icons.search_rounded, size: 19, color: tfMuted),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.close_rounded, size: 17, color: tfMuted),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: tfPaper,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: tfPaper),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: tfPaper),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: tfGold, width: 2),
            ),
          ),
        ),
      ],
    );

    final right = Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TelemetryCard(
                code: '01 · LIVE',
                value: _loading ? '—' : '${_feed.allOpen.length}',
                label: 'Open listings',
                highlight: true,
                onTap: () => Get.toNamed('/activities'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TelemetryCard(
                code: '02 · URGENT',
                value: _loading ? '—' : '${_feed.closing.length}',
                label: 'Closing soon',
                onTap: () => setState(() => _bulletinTab = 'Closing Soon'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TelemetryCard(
                code: '03 · ADMISSIONS',
                value: '1,500+',
                label: 'University routes',
                onTap: () => Get.toNamed('/study/universities'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TelemetryCard(
                code: '04 · DIRECTORY',
                value: 'Programs',
                label: 'Browse by field',
                onTap: () => Get.toNamed('/study/programs'),
              ),
            ),
          ],
        ),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080),
        child: Padding(
          padding: EdgeInsets.fromLTRB(pad, small ? 24 : 36, pad, small ? 28 : 40),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: left),
                    const SizedBox(width: 36),
                    Expanded(flex: 5, child: right),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    left,
                    const SizedBox(height: 24),
                    right,
                  ],
                ),
        ),
      ),
    );
  }

  // ── Featured Admissions Showcase ───────────────────────────────────────────

  Widget _admissionsShowcase(bool small, bool wide) {
    final s = OpportunitySection.study;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tfPaper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tfHair),
        boxShadow: const [
          BoxShadow(color: Color(0x0D0A1931), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: const BoxDecoration(
                color: tfGold,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(5)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(small ? 18 : 26),
                child: wide
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'FEATURED DIVISION · 01',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: tfAccent,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tfTile,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '1,500+ Verified Routes',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: tfNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  s.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: tfNavy,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.subtitle,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: tfMuted,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              TfTextAction(
                                label: 'Universities',
                                icon: Icons.account_balance_outlined,
                                onPressed: () => Get.toNamed('/study/universities'),
                              ),
                              TfTextAction(
                                label: 'Programs',
                                icon: Icons.menu_book_outlined,
                                onPressed: () => Get.toNamed('/study/programs'),
                              ),
                              TfPrimaryButton(
                                label: 'Open Guide',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () => Get.toNamed(s.route),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'FEATURED DIVISION · 1,500+ ROUTES',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: tfAccent,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w700,
                              color: tfNavy,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.subtitle,
                            style: const TextStyle(fontSize: 14, color: tfMuted, height: 1.45),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TfPrimaryButton(
                                label: 'Open Guide',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () => Get.toNamed(s.route),
                              ),
                              TfTextAction(
                                label: 'Universities',
                                onPressed: () => Get.toNamed('/study/universities'),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Three Secondary Divisions Row ──────────────────────────────────────────

  Widget _divisionRow(bool small, bool wide) {
    final others = [
      OpportunitySection.activities,
      OpportunitySection.internships,
      OpportunitySection.programs,
    ];
    if (wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < others.length; i++) ...[
            if (i > 0) const SizedBox(width: 16),
            Expanded(
              child: _DivisionCard(
                index: '0${i + 2}',
                section: others[i],
                openCount: _feed.bySection[others[i].id],
                loading: _loading,
              ),
            ),
          ],
        ],
      );
    }
    return Column(
      children: [
        for (var i = 0; i < others.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _DivisionCard(
            index: '0${i + 2}',
            section: others[i],
            openCount: _feed.bySection[others[i].id],
            loading: _loading,
          ),
        ],
      ],
    );
  }

  // ── Search Results Ledger ──────────────────────────────────────────────────

  Widget _searchResultsPanel(List<Opportunity> matches) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tfPaper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tfHair),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Row(
              children: [
                Text(
                  'Search results (${matches.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tfNavy,
                  ),
                ),
                const Spacer(),
                TfTextAction(
                  label: 'Clear filter',
                  icon: Icons.close_rounded,
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: tfHair),
          if (matches.isEmpty)
            const _Empty('No matching scholarships, admissions, or programs found.')
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [for (final o in matches) _Row(o: o)],
              ),
            ),
        ],
      ),
    );
  }

  // ── Interactive Bulletins Ledger ───────────────────────────────────────────

  Widget _bulletinsPanel(bool small, bool wide) {
    final rows = _activeBulletins();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tfPaper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tfHair),
        boxShadow: const [
          BoxShadow(color: Color(0x0D0A1931), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              small ? 16 : 24,
              small ? 16 : 20,
              small ? 16 : 24,
              16,
            ),
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Live Bulletins & Deadlines Ledger',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: tfNavy,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Click any entry for requirements, benefits, and verified application links.',
                      style: TextStyle(fontSize: 13.5, color: tfMuted),
                    ),
                  ],
                ),
                TfSegmented(
                  items: const ['All Open', 'Closing Soon', 'Must-Know'],
                  selected: _bulletinTab,
                  onSelected: (v) => setState(() => _bulletinTab = v),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: tfHair),
          if (_error != null && !_loading)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tfTile,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: tfHair),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Live deadlines could not load. Check your connection.',
                        style: TextStyle(fontSize: 13.5, color: tfInk),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TfTextAction(label: 'Retry', onPressed: _retry),
                  ],
                ),
              ),
            )
          else if (_loading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: small ? 16 : 24),
              child: Column(
                children: [for (var i = 0; i < 4; i++) const _RowSkeleton()],
              ),
            )
          else if (rows.isEmpty)
            const _Empty('No active entries match this filter right now.')
          else
            Padding(
              padding: EdgeInsets.symmetric(horizontal: small ? 16 : 24),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    _Row(o: rows[i], isLast: i == rows.length - 1),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Telemetry Card in Navy Hero
// ---------------------------------------------------------------------------

class _TelemetryCard extends StatefulWidget {
  final String code;
  final String value;
  final String label;
  final bool highlight;
  final VoidCallback onTap;

  const _TelemetryCard({
    required this.code,
    required this.value,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  State<_TelemetryCard> createState() => _TelemetryCardState();
}

class _TelemetryCardState extends State<_TelemetryCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFF142C56) : tfNavyAlt,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: widget.highlight
                  ? tfGold
                  : (_hover ? const Color(0xFF345694) : tfNavyLine),
              width: widget.highlight ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.code,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: widget.highlight ? tfGold : const Color(0xFFA9B7D0),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFD6DCE8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Division Card (Extracurriculars, Internships, Programs)
// ---------------------------------------------------------------------------

class _DivisionCard extends StatefulWidget {
  final String index;
  final OpportunitySection section;
  final int? openCount;
  final bool loading;

  const _DivisionCard({
    required this.index,
    required this.section,
    required this.openCount,
    required this.loading,
  });

  @override
  State<_DivisionCard> createState() => _DivisionCardState();
}

class _DivisionCardState extends State<_DivisionCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.section;
    final statText = widget.loading
        ? 'Loading...'
        : '${widget.openCount ?? 0} open now';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => Get.toNamed(s.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: tfPaper,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hover ? tfAccent : tfHair,
              width: _hover ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0A1931),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: tfTile,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.index,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: tfNavy,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.loading)
                    const Pulse(child: SkeletonBox(width: 64, height: 12))
                  else
                    Text(
                      statText,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: tfAccent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                s.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: tfNavy,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: tfMuted,
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              Row(
                children: const [
                  Text(
                    'Browse listings',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: tfAccent,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: tfAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bulletin Row
// ---------------------------------------------------------------------------

class _Row extends StatefulWidget {
  final Opportunity o;
  final bool isLast;
  const _Row({required this.o, this.isLast = false});

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final label = o.dateLabel(DateTime.now());
    final urgent = label.tone == DateTone.urgent;
    final dateColor = label.color(tfMuted);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: () => Get.toNamed('/opportunity/${o.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFF9F8F5) : Colors.transparent,
            border: Border(
              bottom: widget.isLast
                  ? BorderSide.none
                  : const BorderSide(color: tfHair, width: 0.7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tfTile,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            o.section.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: tfNavy,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        if (o.category.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Text(
                            o.category,
                            style: const TextStyle(
                              fontSize: 12,
                              color: tfMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      o.title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _hover ? tfAccent : tfNavy,
                      ),
                    ),
                    if (o.shortDescription.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        o.shortDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5, color: tfMuted),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label.text,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: dateColor,
                      fontWeight: urgent ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: tfMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: tfHair, width: 0.7)),
      ),
      child: const Pulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 90, height: 11),
            SizedBox(height: 8),
            SkeletonBox(width: 260, height: 15),
            SizedBox(height: 6),
            SkeletonBox(height: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, color: tfMuted),
        ),
      ),
    );
  }
}
