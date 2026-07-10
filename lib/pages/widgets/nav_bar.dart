import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/category_button.dart';

class NavBar extends StatefulWidget {
  final ValueChanged<String>? onCategorySelected;

  const NavBar({super.key, this.onCategorySelected});

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final List<String> categories = const [
    'All',
    'Competitions',
    'Events',
    'Programs',
    'Volunteering',
    'Scholarships',
    'More',
  ];

  String selected = 'All';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'TF News',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories
                  .map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryButton(
                        label: category,
                        isSelected: category == selected,
                        onTap: () {
                          setState(() => selected = category);
                          widget.onCategorySelected?.call(category);
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}
