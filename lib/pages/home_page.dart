import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/utils/constants/colors.dart';

class _Category {
  final String title, subtitle, route;
  final int count;
  final IconData icon;
  const _Category({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.route,
  });
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _categories = [
    _Category(
      title: 'Scholarships & Admissions',
      subtitle: 'Find you dream university, within Egypt and abroad',
      count: 26,
      icon: Icons.school_outlined,
      route: '/study',
    ),
    _Category(
      title: 'Extracurricular Activities',
      subtitle: 'Volunteering, competitions, clubs, teams, and everything beyond academics',
      count: 12,
      icon: Icons.groups_outlined,
      route: '/activities',
    ),
    _Category(
      title: 'Internships',
      subtitle: 'Real work experience',
      count: 5,
      icon: Icons.work_outline,
      route: '/internships',
    ),
    _Category(
      title: 'Programs',
      subtitle: 'Research, fellowships, and more',
      count: 9,
      icon: Icons.science_outlined,
      route: '/programs',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('TF News',
                    style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 28),
                Text('Welcome back, Bob!',
                    style: t.displaySmall
                        ?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
                const SizedBox(height: 6),
                Text('Stay informed with the latest news and updates. that inrerest ambitious students like you.',
                    style: t.titleMedium?.copyWith(color: Colors.grey)),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth > 600 ? 2 : 1;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _categories.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 230,
                      ),
                      itemBuilder: (_, i) =>
                          _CategoryCard(category: _categories[i]),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _Category category;
  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TColors.primaryBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: TColors.primary),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(category.route),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(category.icon, color: TColors.primary, size: 28),
              const SizedBox(height: 14),
              Text(
                category.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                category.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
              const Spacer(),
              Row(
                children: [
                  Text('${category.count} open',
                      style: TextStyle(
                          color: TColors.primary, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(Icons.arrow_forward, color: TColors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}