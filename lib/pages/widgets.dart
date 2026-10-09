// lib/pages/widgets.dart
// Contains: FilterItem, FilterTile, CategoryButton, NavBar,
// OpportunitiesHeader, TopicRelatedFilter, StatusFilter,
// OpportunityDateLabel (+ helpers), OpportunityCard

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/user_controller.dart';
import 'package:tf_news/data/opportunity.dart';
import 'package:tf_news/utils/constants/colors.dart';

// ---------------------------------------------------------------------------
// Filter building blocks
// ---------------------------------------------------------------------------

class FilterItem {
  final String label;
  final IconData icon;
  const FilterItem(this.label, this.icon);
}

class FilterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterTile({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? TColors.primary : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : Colors.grey[600],
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grey 250px side panel with a title, subtitle and a list of [FilterTile]s.
/// Shared by [TopicRelatedFilter] and [StatusFilter].
class _FilterPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<FilterItem> items;
  final String selected;
  final ValueChanged<String> onSelect;

  const _FilterPanel({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        border: Border.fromBorderSide(BorderSide(color: Colors.grey[300]!)),
        color: Colors.grey[200],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ...items.map(
              (item) => FilterTile(
                icon: item.icon,
                label: item.label,
                isSelected: item.label == selected,
                onTap: () => onSelect(item.label),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Topic filter (was TopicRelatedFilter + FilterColumn).
/// The [title] is now actually shown (e.g. "Degree level").
class TopicRelatedFilter extends StatefulWidget {
  final String title;
  final List<String> topics;
  final ValueChanged<String>? onFilterSelected;

  const TopicRelatedFilter({
    super.key,
    this.title = 'Topics',
    required this.topics,
    this.onFilterSelected,
  });

  @override
  State<TopicRelatedFilter> createState() => _TopicRelatedFilterState();
}

class _TopicRelatedFilterState extends State<TopicRelatedFilter> {
  // Any topic not listed gets the default icon, so new topics never break the UI.
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
  void didUpdateWidget(covariant TopicRelatedFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.topics.contains(selected)) {
      selected = widget.topics.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _FilterPanel(
      title: widget.title,
      subtitle: 'Topic Related Filters',
      items: widget.topics
          .map((t) => FilterItem(t, _icons[t] ?? _defaultIcon))
          .toList(),
      selected: selected,
      onSelect: (label) {
        setState(() => selected = label);
        widget.onFilterSelected?.call(label);
      },
    );
  }
}

/// Status filter (was StatusFilter + StatusColumn).
class StatusFilter extends StatefulWidget {
  final ValueChanged<String>? onFilterSelected;

  const StatusFilter({super.key, this.onFilterSelected});

  @override
  State<StatusFilter> createState() => _StatusFilterState();
}

class _StatusFilterState extends State<StatusFilter> {
  static const List<FilterItem> _items = [
    FilterItem('Open now', Icons.bolt),
    FilterItem('Upcoming', Icons.upcoming_outlined),
  ];

  String selected = 'Open now';

  @override
  Widget build(BuildContext context) {
    return _FilterPanel(
      title: 'Status',
      subtitle: 'Open now or coming soon',
      items: _items,
      selected: selected,
      onSelect: (label) {
        setState(() => selected = label);
        widget.onFilterSelected?.call(label);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Top navigation
// ---------------------------------------------------------------------------

class CategoryButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryButton({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          isSelected ? TColors.primary : TColors.primary.withValues(alpha: 0.08),
        ),
        foregroundColor: WidgetStatePropertyAll(
          isSelected ? Colors.white : TColors.primary,
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected
                  ? TColors.primary
                  : TColors.primary.withValues(alpha: 0.2),
            ),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: (label == 'Must-know')
            ? Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.red
                      : Colors.red.withValues(alpha: 0.8),
                )
            : Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : TColors.primary,
                ),
      ),
    );
  }
}

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

class OpportunitiesHeader extends StatelessWidget {
  final String title;

  const OpportunitiesHeader({super.key, required this.title});

  void popupMenu(Widget content, BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = -box.localToGlobal(Offset.zero);

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        overlay.size.width - position.dx,
        overlay.size.height - position.dy,
      ),
      items: [PopupMenuItem<void>(child: content)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
        ),
        InkWell(
          onTap: () {
            popupMenu(
              const Text('just A joke why you need more filters'),
              context,
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune, size: 16),
                const SizedBox(width: 6),
                Text('Filter', style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Date label
// ---------------------------------------------------------------------------

enum DateTone { urgent, soon, normal, muted }

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatOpportunityDate(DateTime d) =>
    '${d.day} ${_months[d.month - 1]} ${d.year}';

class OpportunityDateLabel {
  final String text;
  final DateTone tone;
  final bool isOpen;

  const OpportunityDateLabel(this.text, this.tone, {required this.isOpen});

  Color color(Color normal) {
    switch (tone) {
      case DateTone.urgent:
        return Colors.red;
      case DateTone.soon:
        return Colors.orange;
      case DateTone.normal:
        return normal;
      case DateTone.muted:
        return Colors.grey;
    }
  }
}

extension OpportunityDateLabelX on Opportunity {
  OpportunityDateLabel dateLabel(DateTime now) {
    if (!hasDates) {
      return const OpportunityDateLabel(
        'Date to be announced',
        DateTone.muted,
        isOpen: false,
      );
    }

    if (isOpenAt(now)) {
      final dl = deadline;
      if (dl == null) {
        return const OpportunityDateLabel(
          'Open now',
          DateTone.normal,
          isOpen: true,
        );
      }
      final today = DateTime.utc(now.year, now.month, now.day);
      final end = DateTime.utc(dl.year, dl.month, dl.day);
      final days = end.difference(today).inDays;

      if (days <= 0) {
        return const OpportunityDateLabel(
          'Closes today',
          DateTone.urgent,
          isOpen: true,
        );
      }
      if (days == 1) {
        return const OpportunityDateLabel(
          'Closes tomorrow',
          DateTone.urgent,
          isOpen: true,
        );
      }
      final tone = days <= 3
          ? DateTone.urgent
          : days <= 7
              ? DateTone.soon
              : DateTone.normal;
      return OpportunityDateLabel('Closes in $days days', tone, isOpen: true);
    }

    final start = startDate;
    if (start != null && start.isAfter(now)) {
      return OpportunityDateLabel(
        'Opens ${formatOpportunityDate(start)}',
        DateTone.muted,
        isOpen: false,
      );
    }

    final next = nextOpeningAt(now);
    if (next == null) {
      return const OpportunityDateLabel(
        'Expected next season',
        DateTone.muted,
        isOpen: false,
      );
    }
    return OpportunityDateLabel(
      'Expected ~${_months[next.month - 1]} ${next.year}',
      DateTone.muted,
      isOpen: false,
    );
  }
}

// ---------------------------------------------------------------------------
// Opportunity card
// ---------------------------------------------------------------------------

class OpportunityCard extends StatefulWidget {
  final Opportunity opportunity;

  const OpportunityCard({super.key, required this.opportunity});

  @override
  State<OpportunityCard> createState() => _OpportunityCardState();
}

class _OpportunityCardState extends State<OpportunityCard> {
  late bool _hasVoted;
  late int _ratingCount;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    final uid = UserController.instance.user.value.id;
    _ratingCount = widget.opportunity.ratingCount;
    _hasVoted = widget.opportunity.voters.contains(uid);
  }

  Future<void> _toggleVote() async {
    if (_voting) return;
    final uid = UserController.instance.user.value.id;
    if (uid.isEmpty) return;
    setState(() => _voting = true);
    final ref = FirebaseFirestore.instance
        .collection('opportunities')
        .doc(widget.opportunity.id);
    try {
      if (_hasVoted) {
        await ref.update({
          'ratingCount': FieldValue.increment(-1),
          'voters': FieldValue.arrayRemove([uid]),
        });
        if (!mounted) return;
        setState(() {
          _hasVoted = false;
          _ratingCount--;
        });
      } else {
        await ref.update({
          'ratingCount': FieldValue.increment(1),
          'voters': FieldValue.arrayUnion([uid]),
        });
        if (!mounted) return;
        setState(() {
          _hasVoted = true;
          _ratingCount++;
        });
      }
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not register your vote.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = widget.opportunity.dateLabel(DateTime.now());
    final dateColor = dateLabel.color(Colors.grey[500]!);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: category + must-know + vote
            Row(
              children: [
                Text(
                  widget.opportunity.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: TColors.primary,
                    letterSpacing: 0.9,
                  ),
                ),
                if (widget.opportunity.mustKnow) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'MUST-KNOW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[700],
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _toggleVote,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _voting
                          ? SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.grey[400],
                              ),
                            )
                          : Icon(
                              _hasVoted
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: _hasVoted
                                  ? Colors.grey[800]
                                  : Colors.grey[400],
                            ),
                      const SizedBox(width: 3),
                      Text(
                        '$_ratingCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              _hasVoted ? Colors.grey[800] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Container(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),

            Text(
              widget.opportunity.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            Expanded(
              child: Text(
                widget.opportunity.shortDescription,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  height: 1.55,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(
                  dateLabel.isOpen
                      ? Icons.schedule_rounded
                      : Icons.event_outlined,
                  size: 12,
                  color: dateColor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    dateLabel.text,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: dateColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.opportunity.topic,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Get.toNamed('/opportunity/${widget.opportunity.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Explore',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}