// lib/pages/admissions/admissions_page.dart
// Entry of Scholarships & Admissions: search a university straight away, or
// choose how to browse.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/admissions_models.dart';
import 'package:tf_news/authentication/admissions_repository.dart';
import 'package:tf_news/pages/admissions/ad_kit.dart';
import 'package:tf_news/utils/ui/tf_minimal.dart';

class AdmissionsPage extends StatefulWidget {
  const AdmissionsPage({super.key});

  @override
  State<AdmissionsPage> createState() => _AdmissionsPageState();
}

class _AdmissionsPageState extends State<AdmissionsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  late Future<List<University>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = AdmissionsRepository().getUniversities();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _results() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<List<University>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('Loading universities...',
                style: TextStyle(color: tfMuted)),
          );
        }
        if (snap.hasError) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('The university list did not load. Try again later.',
                style: TextStyle(color: tfMuted)),
          );
        }
        final all = (snap.data ?? const <University>[])
            .where((u) => '${u.name} ${u.country}'.toLowerCase().contains(q))
            .toList();
        if (all.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text('No university matches that.',
                style: TextStyle(color: tfMuted)),
          );
        }
        final shown = all.take(8).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.5, color: tfHair),
            for (final u in shown) AdUniRow(key: ValueKey(u.uniId), u: u),
            if (all.length > shown.length)
              TfTextAction(
                label: 'Browse all ${all.length} matches',
                onPressed: () => Get.toNamed('/study/universities'),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TfPage(
      backLabel: 'Home',
      slivers: (context, l) {
        final tiles = [
          _PathTile(
            title: 'By university',
            body:
                'You know where you want to study. Pick a university and see every way to get funded there.',
            onTap: () => Get.toNamed('/study/universities'),
          ),
          _PathTile(
            title: 'By program',
            body:
                'Scholarships that are not tied to one university. Pick a program and see where you can use it.',
            onTap: () => Get.toNamed('/study/programs'),
          ),
        ];
        return [
          l.gap(l.small ? 28 : 48),
          l.box(TfTitle(
            title: 'Scholarships\n& Admissions',
            subtitle:
                'Every way to fund your studies at the top universities, copied from official sources.',
            small: l.small,
          )),
          l.gap(28),
          l.box(ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TfSearch(
                  controller: _searchCtrl,
                  hint: 'Search a university or country',
                  onChanged: (v) => setState(() => _query = v),
                ),
                _results(),
              ],
            ),
          )),
          l.gap(l.small ? 48 : 72),
          l.box(l.wide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: tiles[0]),
                      const SizedBox(width: 16),
                      Expanded(child: tiles[1]),
                    ],
                  ),
                )
              : Column(children: [
                  tiles[0],
                  const SizedBox(height: 16),
                  tiles[1],
                ])),
          l.gap(l.small ? 48 : 72),
          l.box(const AdSectionTitle('Quick starts')),
          l.gap(12),
          l.box(const Divider(height: 1, thickness: 0.5, color: tfHair)),
          l.box(AdRow(
            title: 'Universities in Egypt',
            onTap: () => Get.toNamed('/study/universities',
                arguments: const {'countries': ['Egypt']}),
          )),
          l.box(AdRow(
            title: 'Fully funded programs',
            onTap: () => Get.toNamed('/study/programs',
                arguments: const {'coverage': 'full'}),
          )),
          l.box(AdRow(
            title: "Programs for Master's students",
            onTap: () => Get.toNamed('/study/programs',
                arguments: const {'levels': ['Master']}),
          )),
          l.box(AdRow(
            title: 'Programs in Europe',
            onTap: () => Get.toNamed('/study/programs',
                arguments: const {'regions': ['Europe']}),
          )),
        ];
      },
    );
  }
}

class _PathTile extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  const _PathTile({required this.title, required this.body, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $body',
      excludeSemantics: true,
      child: Material(
        color: tfTile,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: const Color(0x0A000000),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: tfInk,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        letterSpacing: -0.5)),
                const SizedBox(height: 8),
                Text(body,
                    style: const TextStyle(
                        color: tfMuted, fontSize: 15, height: 1.5)),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Text('Browse',
                        style: TextStyle(
                            color: tfAccent,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right, color: tfAccent, size: 20),
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