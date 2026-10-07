import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/filter_item.dart';

class FilterColumn extends StatefulWidget {
  final List<String> topics;
  final ValueChanged<String>? onFilterSelected;
  final String title;

  const FilterColumn({
    super.key,
    required this.topics,
    this.onFilterSelected,
    this.title = 'Topics',
  });

  @override
  State<FilterColumn> createState() => _FilterColumnState();
}

class _FilterColumnState extends State<FilterColumn> {
  // Icons are looked up by topic name. Any topic not listed here
  // gets the default icon, so new topics never break the UI.
  static const Map<String, IconData> _icons = {
    'All Opportunities': Icons.list_alt,
    'Egypt': Icons.location_on_outlined,
    'Abroad': Icons.flight_takeoff,
    'Research': Icons.emoji_events_outlined,
    'Mathematics': Icons.functions,
    'Physics': Icons.science_outlined,
    'Computer Science': Icons.terminal,
    'Tech': Icons.terminal,
    'Business': Icons.business_center_outlined,
    'Science': Icons.science_outlined,
    'Biology': Icons.biotech_outlined,
    'Chemistry': Icons.science_outlined,
    'Sustainability': Icons.engineering_outlined,
    'STEM': Icons.atm_outlined,
  };

  static const IconData _defaultIcon = Icons.label_outline;

  late String selected;

  @override
  void initState() {
    super.initState();
    selected = widget.topics.first;
  }

  @override
  void didUpdateWidget(covariant FilterColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the topic list changes and the current choice no longer exists,
    // fall back to the first topic.
    if (!widget.topics.contains(selected)) {
      selected = widget.topics.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.topics
        .map((t) => FilterItem(t, _icons[t] ?? _defaultIcon))
        .toList();

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