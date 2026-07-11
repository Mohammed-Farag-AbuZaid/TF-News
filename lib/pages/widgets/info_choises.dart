import 'package:flutter/material.dart';
import 'package:tf_news/pages/widgets/filter_item.dart';

class InfoChoises extends StatefulWidget {
  final ValueChanged<String>? onFilterSelected;

  const InfoChoises({super.key, this.onFilterSelected});

  @override
  State<InfoChoises> createState() => _InfoChoisesState();
}

class _InfoChoisesState extends State<InfoChoises> {
  final List<FilterItem> items = const [
    FilterItem('About', Icons.info_outline),
    FilterItem('Requirements', Icons.checklist),
    FilterItem('Benefits', Icons.card_giftcard),
    FilterItem('Guidelines', Icons.rule_outlined),
  ];

  String selected = 'About';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
