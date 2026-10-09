// lib/data/opportunity.dart
// Contains: OpportunityStatus, Opportunity (model), OpportunityListX,
// OpportunitySection (config), OpportunityRepository

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Section config (study / activities / internships / programs)
// ---------------------------------------------------------------------------

const _scienceFields = [
  'Mathematics',
  'Physics',
  'Computer Science',
  'Biology',
  'Chemistry',
  'Sustainability',
];

class OpportunitySection {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final List<String> categories;
  final String topicsLabel;
  final List<String> defaultTopics;
  final Map<String, List<String>> topicsByCategory;

  const OpportunitySection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.categories,
    this.topicsLabel = 'Topics',
    required this.defaultTopics,
    this.topicsByCategory = const {},
  });

  static const String allTopics = 'All Opportunities';
  static const String mustKnow = 'Must-know';

  List<String> topicsFor(String? category) {
    final topics = topicsByCategory[category] ?? defaultTopics;
    return [allTopics, ...topics];
  }

  static const study = OpportunitySection(
    id: 'study',
    title: 'Scholarships & Admissions',
    subtitle: 'Find your dream university, within Egypt and abroad',
    icon: Icons.school_outlined,
    route: '/study',
    categories: ['All', 'Egypt', 'US', 'China', 'Europe', 'Other', mustKnow],
    topicsLabel: 'Degree level',
    defaultTopics: ['Bachelor', 'Master', 'PhD'],
  );

  static const activities = OpportunitySection(
    id: 'activities',
    title: 'Extracurricular Activities',
    subtitle:
        'Volunteering, competitions, clubs, teams, and everything beyond academics',
    icon: Icons.groups_outlined,
    route: '/activities',
    categories: [
      'All', 'Volunteering', 'Competitions', 'Clubs & teams',
      'Hackathons', 'Events', 'Workshops', mustKnow,
    ],
    defaultTopics: [
      'STEM', 'Mathematics', 'Physics', 'Computer Science',
      'Business', 'Science', 'Sustainability', 'Biology', 'Chemistry',
    ],
    topicsByCategory: {
      'Volunteering': ['Education', 'Environment', 'Health', 'Community'],
      'Clubs & teams': ['Debate', 'Model UN', 'Robotics', 'Arts'],
      'Hackathons': ['Computer Science', 'Sustainability', 'Business', 'STEM'],
    },
  );

  static const internships = OpportunitySection(
    id: 'internships',
    title: 'Internships',
    subtitle: 'Real work experience',
    icon: Icons.work_outline,
    route: '/internships',
    categories: ['All', 'Egypt', 'Abroad', 'Remote', mustKnow],
    defaultTopics: ['Tech', 'Business', 'Science'],
  );

  static const programs = OpportunitySection(
    id: 'programs',
    title: 'Programs',
    subtitle: 'Research, exchange, leadership, and more',
    icon: Icons.science_outlined,
    route: '/programs',
    categories: ['All', 'Research', 'Exchange', 'Leadership', mustKnow],
    defaultTopics: _scienceFields,
    topicsByCategory: {
      'Research': _scienceFields,
      'Exchange': ['Cultural', 'Academic', 'Language'],
      'Leadership': ['Public speaking', 'Entrepreneurship', 'Civic engagement'],
    },
  );

  static const all = [study, activities, internships, programs];
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

class OpportunityRepository {
  final CollectionReference _opportunitiesRef =
      FirebaseFirestore.instance.collection('opportunities');

  Future<List<Opportunity>> getOpportunities({
    required String section,
    String? category,
    String? topic,
    bool? mustKnow,
  }) async {
    Query query = _opportunitiesRef.where('section', isEqualTo: section);

    if (mustKnow == true) {
      query = query.where('mustKnow', isEqualTo: true);
    } else if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (topic != null && topic.isNotEmpty) {
      query = query.where('topic', isEqualTo: topic);
    }

    final snapshot = await query.get();

    final result = <Opportunity>[];
    for (final doc in snapshot.docs) {
      try {
        result.add(Opportunity.fromFirestore(doc));
      } catch (e) {
        debugPrint('Skipping bad opportunity ${doc.id}: $e');
      }
    }
    return result;
  }

  Future<Opportunity?> getOpportunityById(String id) async {
    final doc = await _opportunitiesRef.doc(id).get();
    if (!doc.exists) return null;
    return Opportunity.fromFirestore(doc);
  }

  /// Count of currently open opportunities, per section id.
  Future<Map<String, int>> getOpenCounts() async {
    final snapshot = await _opportunitiesRef.get();
    final now = DateTime.now();
    final counts = <String, int>{};

    for (final doc in snapshot.docs) {
      try {
        final o = Opportunity.fromFirestore(doc);
        if (o.isOpenAt(now)) {
          counts[o.section] = (counts[o.section] ?? 0) + 1;
        }
      } catch (e) {
        debugPrint('Skipping bad opportunity ${doc.id}: $e');
      }
    }
    return counts;
  }
}