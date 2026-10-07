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
  final String route;
  final List<String> categories; 
  final String topicsLabel; 
  final List<String> defaultTopics; 
  final Map<String, List<String>> topicsByCategory; 

  const OpportunitySection({
    required this.id,
    required this.title,
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
    route: '/study',
    categories: ['All', 'Egypt', 'US', 'China', 'Europe', 'Other', mustKnow],
    topicsLabel: 'Degree level',
    defaultTopics: ['Bachelor', 'Master', 'PhD'],
  );

  static const activities = OpportunitySection(
    id: 'activities',
    title: 'Extracurricular Activities',
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
    route: '/internships',
    categories: ['All', 'Egypt', 'Abroad', 'Remote', mustKnow],
    defaultTopics: ['Tech', 'Business', 'Science'],
  );

  static const programs = OpportunitySection(
    id: 'programs',
    title: 'Programs',
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