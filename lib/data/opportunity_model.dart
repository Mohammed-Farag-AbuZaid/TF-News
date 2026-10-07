import 'package:cloud_firestore/cloud_firestore.dart';
enum OpportunityStatus { open, upcoming }

class Opportunity {
  final String id;
  final String section;
  final String title;
  final String shortDescription;
  final String aboutMarkdown;
  final String requirementsMarkdown;
  final String benefitsMarkdown;
  final String guidelinesMarkdown;
  final DateTime? startDate;
  final DateTime? deadline; 
  final String category;
  final String topic;
  final String link;
  final int ratingCount;
  final bool mustKnow;
  final List<String> voters;

  Opportunity({
    required this.id,
    required this.section,
    required this.title,
    required this.shortDescription,
    required this.aboutMarkdown,
    required this.requirementsMarkdown,
    required this.benefitsMarkdown,
    required this.guidelinesMarkdown,
    required this.startDate,
    required this.deadline,
    required this.category,
    required this.topic,
    required this.link,
    required this.ratingCount,
    this.mustKnow = false,
    this.voters = const [],
  });

  bool get hasDates => startDate != null || deadline != null;
  DateTime? get _deadlineEnd {
    final d = deadline;
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, 23, 59, 59);
  }

  bool isOpenAt(DateTime now) {
    if (!hasDates) return false;
    final start = startDate;
    final end = _deadlineEnd;
    final started = start == null || !start.isAfter(now);
    final notClosed = end == null || !end.isBefore(now);
    return started && notClosed;
  }

  OpportunityStatus statusAt(DateTime now) =>
      isOpenAt(now) ? OpportunityStatus.open : OpportunityStatus.upcoming;

  bool isExpectedAt(DateTime now) {
    final start = startDate;
    final end = _deadlineEnd;
    if (isOpenAt(now)) return false;
    if (start != null && start.isAfter(now)) return false; // announced
    return end != null && end.isBefore(now);
  }

  DateTime? nextOpeningAt(DateTime now) {
    final start = startDate;
    if (start == null) return null;
    var d = start;
    while (!d.isAfter(now)) {
      d = DateTime(d.year + 1, d.month, d.day);
    }
    return d;
  }

  factory Opportunity.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Opportunity(
      id: doc.id,
      section: data['section'] ?? '',
      title: data['title'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      aboutMarkdown: data['aboutMarkdown'] ?? '',
      requirementsMarkdown: data['requirementsMarkdown'] ?? '',
      benefitsMarkdown: data['benefitsMarkdown'] ?? '',
      guidelinesMarkdown: data['guidelinesMarkdown'] ?? '',
      startDate: _toDate(data['startDate']),
      deadline: _toDate(data['deadline']),
      category: data['category'] ?? '',
      topic: data['topic'] ?? '',
      link: data['link'] ?? '',
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      mustKnow: data['mustKnow'] as bool? ?? false,
      voters: List<String>.from(data['voters'] ?? []),
    );
  }
}

DateTime? _toDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

int _nullsLast(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

extension OpportunityListX on List<Opportunity> {
  List<Opportunity> forStatus(OpportunityStatus status, {DateTime? now}) {
    final t = now ?? DateTime.now();
    final matching = where((o) => o.statusAt(t) == status).toList();

    if (status == OpportunityStatus.open) {
      matching.sort((a, b) => _nullsLast(a.deadline, b.deadline));
    } else {
      matching.sort(
        (a, b) => _nullsLast(a.nextOpeningAt(t), b.nextOpeningAt(t)),
      );
    }
    return matching;
  }
}