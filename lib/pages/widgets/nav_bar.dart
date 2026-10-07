import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/category_button.dart';

class NavBar extends StatefulWidget {
  final List<String> categories;
  final ValueChanged<String>? onCategorySelected;
  final String initialCategory;

  const NavBar({
    super.key,
    required this.categories,
    this.onCategorySelected,
    this.initialCategory = 'All',
  });

  @override
  State<NavBar> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late String selected;

  @override
  void initState() {
    super.initState();
    selected = widget.initialCategory;
  }

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
              children: widget.categories
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