// lib/pages/home_page.dart
// Home — TF Oxford & Stone editorial observatory for TF News (news.tfunions.com).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/authentication_repository.dart';
import 'package:tf_news/authentication/login_controller.dart';
import 'package:tf_news/authentication/login_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final matches = _matches();
    return Scaffold(
      backgroundColor: tfCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, c) {
            final small = c.maxWidth < TfBreakpoints.mobile;
            final pad = small ? 16.0 : tfSidePadding(c.maxWidth) + 8;
            final wide = c.maxWidth >= 880;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _heroStage(pad, small, wide),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(pad, small ? 16 : 24, pad, 56),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_error != null && _query.trim().isNotEmpty)
                              _ErrorBanner(onRetry: _retry),
                            if (_query.trim().isNotEmpty)
                              _searchResultsPanel(matches)
                            else
                              _launchpadGrid(small, wide),
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

  // ── Compact Inline Account & Brand Controls (No heavy top bar) ────────────

  void _openAuth(bool register) {
    final c = Get.isRegistered<LoginController>()
        ? Get.find<LoginController>()
        : Get.put(LoginController());
    c.isRegisterMode.value = register;
    Get.to(() => const LoginScreen());
  }

  Widget _heroIdentityBar(bool small) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tfNavy,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            'TF',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(width: 9),
        const Text(
          'TF News',
          style: TextStyle(
            fontFamily: 'Bricolage Grotesque',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: tfInk,
            letterSpacing: -0.3,
          ),
        ),
        const Spacer(),
        Obx(() {
          final u = UserController.instance.user.value;
          final fbUser = AuthenticationRepository.instance.authUser;
          final rawName = u.firstName.trim().isNotEmpty
              ? u.firstName.trim()
              : (fbUser?.displayName?.trim().split(' ').first ??
                  fbUser?.email?.split('@').first ??
                  '');
          if (rawName.isEmpty) {
            return Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              children: [
                InkWell(
                  onTap: () => _openAuth(false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: small ? 10 : 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: tfPaper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tfHair),
                    ),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: tfInk,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _openAuth(true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: small ? 11 : 13,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: tfNavy,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          return PopupMenuButton<String>(
            tooltip: 'Account options',
            color: tfPaper,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: tfHair),
            ),
            onSelected: (value) async {
              if (value == 'switch') {
                _openAuth(false);
              } else if (value == 'create') {
                _openAuth(true);
              } else if (value == 'signout') {
                await AuthenticationRepository.instance.logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'switch',
                child: Text('Switch account'),
              ),
              PopupMenuItem(
                value: 'create',
                child: Text('Create new account'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'signout',
                child: Text(
                  'Sign out',
                  style: TextStyle(color: tfUrgent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tfTealSoft,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: tfTealBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: tfGood,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: small ? 120 : 180),
                    child: Text(
                      'Scholar · $rawName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: tfGood,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.expand_more_rounded,
                    size: 16,
                    color: tfGood,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _navChip(String label, String route) {
    return InkWell(
      onTap: () => Get.toNamed(route),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: tfPaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tfHair),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: tfMuted,
            fontWeight: FontWeight.w600,
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
        _heroIdentityBar(small),
        SizedBox(height: small ? 16 : 22),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _navChip('Admissions', '/study'),
            _navChip('Directories', '/directories'),
            _navChip('Bulletins', '/bulletins'),
            _navChip('Universities', '/study/universities'),
          ],
        ),
        SizedBox(height: small ? 14 : 18),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tfTealSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tfTealBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: tfGood,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Opportunities & admissions bulletin',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: tfGood,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Scholarships, university admissions, and verified pathways.',
          style: TextStyle(
            fontFamily: 'Bricolage Grotesque',
            fontSize: small ? 27 : 40,
            fontWeight: FontWeight.w700,
            color: tfInk,
            letterSpacing: -1.1,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Compare 1,500+ international admission routes, track closing scholarship deadlines, and browse vetted research, internship, and extracurricular programs across Egypt.',
          style: TextStyle(
            fontSize: 15.5,
            color: tfMuted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 22),
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
                ? Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: tfTile,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: const Color(0xFFDCD9D0)),
                          ),
                          child: const Text(
                            '/',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tfMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
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
              horizontal: 16,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: tfHair),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: tfHair),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: tfAccent, width: 1.5),
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
                code: '01 — Live',
                value: _loading ? '—' : '${_feed.allOpen.length}',
                label: 'Open listings',
                highlight: true,
                onTap: () => Get.toNamed('/bulletins'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TelemetryCard(
                code: '02 — Urgent',
                value: _loading ? '—' : '${_feed.closing.length}',
                label: 'Closing soon',
                onTap: () => Get.toNamed('/bulletins?tab=closing'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TelemetryCard(
                code: '03 — Admissions',
                value: '1,500+',
                label: 'University routes',
                onTap: () => Get.toNamed('/study/universities'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TelemetryCard(
                code: '04 — Directories',
                value: '4 tracks',
                label: 'Browse divisions',
                onTap: () => Get.toNamed('/directories'),
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
          padding: EdgeInsets.fromLTRB(pad, small ? 18 : 34, pad, small ? 20 : 28),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 6, child: left),
                    const SizedBox(width: 40),
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

  // ── Clean 4-Destination Launchpad Grid ───────────────────────────────────

  Widget _launchpadGrid(bool small, bool wide) {
    final destinations = [
      _LaunchCardData(
        code: '01 · Admissions',
        title: 'University Admissions Guide',
        subtitle: 'Compare 1,500+ verified international pathways, scholarships, and financial aid criteria.',
        cta: 'Open admissions guide',
        route: '/study',
      ),
      _LaunchCardData(
        code: '02 · Directories',
        title: 'Opportunity Directories',
        subtitle: 'Browse Extracurricular Activities, Internships, and Pre-College Research Programs.',
        cta: 'View directories',
        route: '/directories',
      ),
      _LaunchCardData(
        code: '03 · Real-Time Feed',
        title: 'Live Bulletins & Deadlines',
        subtitle: _loading
            ? 'Inspect All Open, Closing Soon, and Essential student deadlines.'
            : '${_feed.allOpen.length} open listings · ${_feed.closing.length} closing soon.',
        cta: 'Open bulletins ledger',
        route: '/bulletins',
      ),
      _LaunchCardData(
        code: '04 · Majors & Campuses',
        title: 'Universities & Fields Finder',
        subtitle: 'Jump straight to searchable universities or filter opportunities by academic field.',
        cta: 'Browse universities',
        route: '/study/universities',
      ),
    ];

    if (wide) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _LaunchpadCard(data: destinations[0])),
              const SizedBox(width: 16),
              Expanded(child: _LaunchpadCard(data: destinations[1])),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _LaunchpadCard(data: destinations[2])),
              const SizedBox(width: 16),
              Expanded(child: _LaunchpadCard(data: destinations[3])),
            ],
          ),
        ],
      );
    }

    return Column(
      children: [
        for (var i = 0; i < destinations.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _LaunchpadCard(data: destinations[i]),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tfHair),
        boxShadow: const [
          BoxShadow(color: Color(0x0A161A22), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
            child: Row(
              children: [
                Text(
                  'Search results (${matches.length})',
                  style: const TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: tfInk,
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
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [for (final o in matches) _Row(o: o)],
              ),
            ),
        ],
      ),
    );
  }
}

class _LaunchCardData {
  final String code;
  final String title;
  final String subtitle;
  final String cta;
  final String route;
  const _LaunchCardData({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.route,
  });
}

class _LaunchpadCard extends StatefulWidget {
  final _LaunchCardData data;
  const _LaunchpadCard({required this.data});

  @override
  State<_LaunchpadCard> createState() => _LaunchpadCardState();
}

class _LaunchpadCardState extends State<_LaunchpadCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => Get.toNamed(d.route),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: tfPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hover ? tfAccent : tfHair,
              width: _hover ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(color: Color(0x0A161A22), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.code,
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: tfGood,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                d.title,
                style: const TextStyle(
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: tfInk,
                  letterSpacing: -0.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d.subtitle,
                style: const TextStyle(fontSize: 13.5, color: tfMuted, height: 1.55),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Text(
                    d.cta,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tfAccent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded, size: 15, color: tfAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorBanner({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tfTile,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tfHair),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Live feed could not refresh. Showing cached results if available.',
              style: TextStyle(fontSize: 13.5, color: tfInk),
            ),
          ),
          const SizedBox(width: 12),
          TfTextAction(label: 'Retry', onPressed: onRetry),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dedicated Page: Opportunity Directories (/directories)
// ---------------------------------------------------------------------------

class DirectoriesPage extends StatefulWidget {
  const DirectoriesPage({super.key});

  @override
  State<DirectoriesPage> createState() => _DirectoriesPageState();
}

class _DirectoriesPageState extends State<DirectoriesPage> {
  _Feed _feed = const _Feed();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed().then((feed) {
      if (!mounted) return;
      setState(() {
        _feed = feed;
        _loading = false;
      });
    }).catchError((_) {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TfPage(
      backLabel: 'Home',
      slivers: (context, l) => [
        l.gap(16),
        l.box(
          TfTitle(
            title: 'Opportunity directories',
            subtitle: 'Browse admissions guides, extracurricular activities, internships, and research programs.',
            small: l.small,
          ),
        ),
        l.gap(20),
        l.box(_admissionsShowcase(l.small, l.wide)),
        l.gap(20),
        l.box(_divisionRow(l.small, l.wide)),
      ],
    );
  }

  Widget _admissionsShowcase(bool small, bool wide) {
    final s = OpportunitySection.study;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: tfPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tfHair),
        boxShadow: const [
          BoxShadow(color: Color(0x0A161A22), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: tfGood,
                borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(small ? 20 : 28),
                child: wide
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      '01 · Featured division',
                                      style: TextStyle(
                                        fontFamily: 'JetBrains Mono',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: tfGood,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: tfTile,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        '1,500+ verified routes',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: tfInk,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  s.title,
                                  style: const TextStyle(
                                    fontFamily: 'Bricolage Grotesque',
                                    fontSize: 25,
                                    fontWeight: FontWeight.w700,
                                    color: tfInk,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  s.subtitle,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    color: tfMuted,
                                    height: 1.55,
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
                                label: 'Open guide',
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
                            '01 · Verified admissions (1,500+ routes)',
                            style: TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: tfGood,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            s.title,
                            style: const TextStyle(
                              fontFamily: 'Bricolage Grotesque',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: tfInk,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.subtitle,
                            style: const TextStyle(fontSize: 14, color: tfMuted, height: 1.5),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TfPrimaryButton(
                                label: 'Open guide',
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

  Widget _divisionRow(bool small, bool wide) {
    final others = [
      OpportunitySection.activities,
      OpportunitySection.internships,
      OpportunitySection.programs,
    ];
    if (wide) {
      return IntrinsicHeight(
        child: Row(
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
        ),
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
}

// ---------------------------------------------------------------------------
// Dedicated Page: Live Bulletins & Deadlines (/bulletins)
// ---------------------------------------------------------------------------

class BulletinsPage extends StatefulWidget {
  const BulletinsPage({super.key});

  @override
  State<BulletinsPage> createState() => _BulletinsPageState();
}

class _BulletinsPageState extends State<BulletinsPage> {
  Future<_Feed>? _future;
  _Feed _feed = const _Feed();
  bool _loading = true;
  Object? _error;
  String _bulletinTab = 'All Open';

  @override
  void initState() {
    super.initState();
    final tabParam = Get.parameters['tab'];
    if (tabParam == 'closing') {
      _bulletinTab = 'Closing Soon';
    } else if (tabParam == 'essential') {
      _bulletinTab = 'Must-Know';
    }
    _retry();
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
    final rows = _activeBulletins();
    return TfPage(
      backLabel: 'Home',
      slivers: (context, l) => [
        l.gap(16),
        l.box(
          TfTitle(
            title: 'Live bulletins & deadlines',
            subtitle: 'Click any entry for requirements, benefits, and verified application links.',
            small: l.small,
          ),
        ),
        l.gap(20),
        l.box(
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: tfPaper,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tfHair),
              boxShadow: const [
                BoxShadow(color: Color(0x0A161A22), blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    l.small ? 18 : 24,
                    l.small ? 16 : 20,
                    l.small ? 18 : 24,
                    16,
                  ),
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TfSegmented(
                        items: const ['All Open', 'Closing Soon', 'Must-Know'],
                        selected: _bulletinTab,
                        onSelected: (v) => setState(() => _bulletinTab = v),
                      ),
                      TfTextAction(
                        label: 'Refresh',
                        icon: Icons.refresh_rounded,
                        onPressed: _retry,
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
                        borderRadius: BorderRadius.circular(10),
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
                    padding: EdgeInsets.symmetric(horizontal: l.small ? 18 : 24),
                    child: Column(
                      children: [for (var i = 0; i < 4; i++) const _RowSkeleton()],
                    ),
                  )
                else if (rows.isEmpty)
                  const _Empty('No active entries match this filter right now.')
                else
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: l.small ? 18 : 24),
                    child: Column(
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          _Row(o: rows[i], isLast: i == rows.length - 1),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Telemetry Card
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
    final bgColor = widget.highlight
        ? (_hover ? const Color(0xFFE3F3EF) : tfTealSoft)
        : (_hover ? const Color(0xFFFAF9F6) : tfPaper);
    final borderColor = widget.highlight
        ? tfGood
        : (_hover ? tfAccent : tfHair);

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
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: widget.highlight || _hover ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A161A22),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.code,
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: widget.highlight ? tfGood : tfMuted,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.value,
                style: TextStyle(
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  color: widget.highlight ? tfGood : tfInk,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: tfMuted,
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: tfPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hover ? tfAccent : tfHair,
              width: _hover ? 1.5 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A161A22),
                blurRadius: 4,
                offset: Offset(0, 1),
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
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.index,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: tfInk,
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
                        color: tfGood,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                s.title,
                style: const TextStyle(
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: tfInk,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                s.subtitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: tfMuted,
                  height: 1.5,
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
                      fontWeight: FontWeight.w600,
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
    final rawSection = o.section.trim();
    final sectionLabel = rawSection.isEmpty
        ? 'Opportunity'
        : '${rawSection[0].toUpperCase()}${rawSection.substring(1)}';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: InkWell(
        onTap: () => Get.toNamed('/opportunity/${o.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFFAF9F6) : Colors.transparent,
            border: Border(
              bottom: widget.isLast
                  ? BorderSide.none
                  : const BorderSide(color: tfHair, width: 0.8),
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
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: tfTile,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sectionLabel,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: tfInk,
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
                        color: _hover ? tfAccent : tfInk,
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
