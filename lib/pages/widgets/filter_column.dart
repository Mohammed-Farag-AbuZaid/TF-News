import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/filter_item.dart';

class FilterColumn extends StatefulWidget {
  final ValueChanged<String>? onFilterSelected;

  const FilterColumn({super.key, this.onFilterSelected});

  @override
  State<FilterColumn> createState() => _FilterColumnState();
}

class _FilterColumnState extends State<FilterColumn> {
  final List<FilterItem> items = const [
    FilterItem('All Opportunities', Icons.list_alt),
    FilterItem('Research', Icons.emoji_events_outlined),
    FilterItem('Mathematics', Icons.functions),
    FilterItem('Physics', Icons.science_outlined),
    FilterItem('Computer Science', Icons.terminal),
    FilterItem('Biology', Icons.biotech_outlined),
    FilterItem('Chemistry', Icons.science_outlined),
    FilterItem('Sustainability', Icons.engineering_outlined),
    FilterItem('STEM', Icons.atm_outlined),
  ];

  String selected = 'All Opportunities';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'Topic Related Filters',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (item) => FilterTile(
              icon: item.icon,
              label: item.label,
              isSelected: item.label == selected,
              onTap: () {
                setState(() => selected = item.label);
                widget.onFilterSelected?.call(item.label);
              },
            ),
          ),
        ],
      ),
    );
  }
}

