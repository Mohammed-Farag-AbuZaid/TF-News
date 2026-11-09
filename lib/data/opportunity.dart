// lib/data/opportunity.dart
// Contains: OpportunityStatus, Opportunity (model), OpportunityListX,
// OpportunitySection (config), OpportunityRepository

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String kTfApiBaseUrl = 'https://n8n.tfunions.com/tf-api';

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
    if (start != null && start.isAfter(now)) return false;
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

  factory Opportunity.fromJson(Map<String, dynamic> data, {String? docId}) {
    return Opportunity(
      id: (docId ?? data['id'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      shortDescription: (data['shortDescription'] ?? '').toString(),
      aboutMarkdown: (data['aboutMarkdown'] ?? '').toString(),
      requirementsMarkdown: (data['requirementsMarkdown'] ?? '').toString(),
      benefitsMarkdown: (data['benefitsMarkdown'] ?? '').toString(),
      guidelinesMarkdown: (data['guidelinesMarkdown'] ?? '').toString(),
      startDate: _toDate(data['startDate']),
      deadline: _toDate(data['deadline']),
      category: (data['category'] ?? '').toString(),
      topic: (data['topic'] ?? '').toString(),
      link: (data['link'] ?? '').toString(),
      ratingCount: (data['ratingCount'] as num?)?.toInt() ?? 0,
      mustKnow: data['mustKnow'] as bool? ?? false,
      voters: List<String>.from(data['voters'] ?? []),
    );
  }

  factory Opportunity.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return Opportunity.fromJson(data, docId: doc.id);
  }
}

DateTime? _toDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  if (value is Map) {
    final sec = value['_seconds'] ?? value['seconds'];
    if (sec is num) {
      return DateTime.fromMillisecondsSinceEpoch((sec * 1000).toInt());
    }
  }
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
// Repository (VPS API primary, Firestore fallback)
// ---------------------------------------------------------------------------

class OpportunityRepository {
  static List<Opportunity>? _cachedAll;

  Future<List<Opportunity>> fetchAllOpportunities({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedAll != null && _cachedAll!.isNotEmpty) {
      return _cachedAll!;
    }
    try {
      final res = await http
          .get(Uri.parse('$kTfApiBaseUrl/api/collections/opportunities'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (body['items'] as List<dynamic>? ?? []);
        final parsed = <Opportunity>[];
        for (final item in items) {
          if (item is Map<String, dynamic>) {
            try {
              parsed.add(Opportunity.fromJson(item));
            } catch (_) {}
          }
        }
        if (parsed.isNotEmpty) {
          _cachedAll = parsed;
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('VPS API fetch failed, falling back: $e');
    }

    // Fallback to Firestore if VPS API is unreachable
    final snapshot =
        await FirebaseFirestore.instance.collection('opportunities').get();
    final result = <Opportunity>[];
    for (final doc in snapshot.docs) {
      try {
        result.add(Opportunity.fromFirestore(doc));
      } catch (e) {
        debugPrint('Skipping bad opportunity ${doc.id}: $e');
      }
    }
    _cachedAll = result;
    return result;
  }

  Future<List<Opportunity>> getOpportunities({
    required String section,
    String? category,
    String? topic,
    bool? mustKnow,
  }) async {
    final all = await fetchAllOpportunities();
    return all.where((o) {
      if (o.section != section) return false;
      if (mustKnow == true && !o.mustKnow) return false;
      if (mustKnow != true &&
          category != null &&
          category.isNotEmpty &&
          o.category != category) {
        return false;
      }
      if (topic != null && topic.isNotEmpty && o.topic != topic) return false;
      return true;
    }).toList();
  }

  Future<Opportunity?> getOpportunityById(String id) async {
    try {
      final res = await http
          .get(Uri.parse('$kTfApiBaseUrl/api/collections/opportunities/$id'))
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        final data = (body['data'] as Map<String, dynamic>?) ?? body;
        return Opportunity.fromJson(data, docId: id);
      }
    } catch (_) {}

    final all = await fetchAllOpportunities();
    for (final o in all) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// Count of currently open opportunities, per section id.
  Future<Map<String, int>> getOpenCounts() async {
    final all = await fetchAllOpportunities();
    final now = DateTime.now();
    final counts = <String, int>{};

    for (final o in all) {
      if (o.isOpenAt(now)) {
        counts[o.section] = (counts[o.section] ?? 0) + 1;
      }
    }
    return counts;
  }
}
