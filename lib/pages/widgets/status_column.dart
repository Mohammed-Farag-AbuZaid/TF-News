import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/filter_item.dart';

class StatusColumn extends StatefulWidget {
  final ValueChanged<String>? onFilterSelected;

  const StatusColumn({super.key, this.onFilterSelected});

  @override
  State<StatusColumn> createState() => _StatusColumnState();
}

class _StatusColumnState extends State<StatusColumn> {
  final List<FilterItem> items = const [
    FilterItem('Active', Icons.bolt),
    FilterItem('Ended', Icons.event_busy),
    FilterItem('Upcoming', Icons.upcoming_outlined),
    FilterItem('Most Popular', Icons.local_fire_department),
  ];

  String selected = 'Active';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Status Related Filters',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
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
