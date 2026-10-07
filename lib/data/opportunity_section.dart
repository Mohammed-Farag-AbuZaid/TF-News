import 'package:flutter/material.dart';

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