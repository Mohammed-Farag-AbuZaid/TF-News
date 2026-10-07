import 'package:flutter/material.dart';
import 'package:tf_news/data/opportunity_model.dart';

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