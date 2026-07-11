import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedOpportunities() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  final collection = firestore.collection('opportunities');

  final now = DateTime.now();

  final List<Map<String, dynamic>> sampleData = [
    {
      'title': 'Google Summer of Code 2026',
      'shortDescription':
          'A global program bringing new contributors into open source software development, working remotely with experienced mentors.',
      'aboutMarkdown':
          'Google Summer of Code (GSoC) is a **global, online program** focused on bringing new contributors into open source. Participants work remotely with an organization over a 12+ week period.',
      'requirementsMarkdown':
          '- At least 18 years old\n- Student or new to open source\n- Eligible to work in your country',
      'benefitsMarkdown':
          '- Stipend for contributions\n- Direct mentorship\n- Certificate and public recognition',
      'guidelinesMarkdown':
          '1. Pick an organization\n2. Submit a proposal\n3. Get accepted\n4. Code for 12+ weeks',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 10))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 40))),
      'category': 'Programs',
      'topic': 'Computer Science',
      'link': 'https://summerofcode.withgoogle.com',
      'ratingCount': 128,
    },
    {
      'title': 'International Mathematical Olympiad 2026',
      'shortDescription':
          'The oldest and most prestigious international mathematics competition for pre-university students.',
      'aboutMarkdown':
          'The IMO is held annually, bringing together the brightest young mathematicians from over 100 countries to solve six challenging problems.',
      'requirementsMarkdown':
          '- Pre-university student\n- Selected via national olympiad',
      'benefitsMarkdown': '- Medals and recognition\n- University scholarship opportunities',
      'guidelinesMarkdown':
          '1. Qualify through your national olympiad\n2. Join national team training\n3. Compete over two days',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 60))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 5))),
      'category': 'Competitions',
      'topic': 'Mathematics',
      'link': 'https://www.imo-official.org',
      'ratingCount': 302,
    },
    {
      'title': 'CERN Summer Student Programme',
      'shortDescription':
          'Work alongside physicists at CERN on real particle physics research and detector technology.',
      'aboutMarkdown':
          'The CERN Summer Student Programme invites undergraduate and graduate students to spend two months at CERN, attending lectures and contributing to ongoing research projects.',
      'requirementsMarkdown':
          '- Enrolled in physics/engineering degree\n- Basic programming knowledge',
      'benefitsMarkdown': '- Monthly stipend\n- Access to CERN facilities\n- Lecture series',
      'guidelinesMarkdown':
          '1. Submit application and transcripts\n2. Interview if shortlisted\n3. Relocate to Geneva for 8 weeks',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 90))),
      'deadline': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
      'category': 'Programs',
      'topic': 'Physics',
      'link': 'https://home.cern/summer-student-programme',
      'ratingCount': 87,
    },
    {
      'title': 'iGEM Competition 2026',
      'shortDescription':
          'A synthetic biology competition where student teams design and build genetically engineered systems.',
      'aboutMarkdown':
          'iGEM brings together interdisciplinary teams to work on synthetic biology projects addressing real-world challenges, presented at the annual Giant Jamboree.',
      'requirementsMarkdown': '- Form a team of 5+\n- Register through a university or independent team',
      'benefitsMarkdown': '- Lab funding support\n- Global recognition\n- Networking with scientists',
      'guidelinesMarkdown':
          '1. Register your team\n2. Design your project\n3. Present at the Jamboree',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 20))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 150))),
      'category': 'Competitions',
      'topic': 'Biology',
      'link': 'https://igem.org',
      'ratingCount': 54,
    },
    {
      'title': 'Chemistry Olympiad National Trials',
      'shortDescription':
          'National-level trials selecting students for the International Chemistry Olympiad team.',
      'aboutMarkdown':
          'A series of exams and lab practicals to identify and train the national chemistry team for international competition.',
      'requirementsMarkdown': '- High school student\n- Strong chemistry background',
      'benefitsMarkdown': '- Specialized training camp\n- Chance to represent your country',
      'guidelinesMarkdown':
          '1. Register for trials\n2. Pass written exam\n3. Attend training camp',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 5))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 25))),
      'category': 'Competitions',
      'topic': 'Chemistry',
      'link': 'https://www.icho-official.org',
      'ratingCount': 41,
    },
    {
      'title': 'UN Youth Climate Summit',
      'shortDescription':
          'A global gathering of young climate activists and innovators presenting solutions to policymakers.',
      'aboutMarkdown':
          'The summit brings together youth delegates from around the world to share sustainability projects and engage directly with UN officials.',
      'requirementsMarkdown': '- Age 18-29\n- Active in a sustainability project',
      'benefitsMarkdown': '- Travel and accommodation covered\n- Direct policymaker access',
      'guidelinesMarkdown':
          '1. Submit your project\n2. Get shortlisted\n3. Attend the summit',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 45))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 15))),
      'category': 'Events',
      'topic': 'Sustainability',
      'link': 'https://www.un.org/youthclimatesummit',
      'ratingCount': 19,
    },
    {
      'title': 'Red Cross Youth Volunteer Program',
      'shortDescription':
          'Join local and international relief efforts as a trained youth volunteer with the Red Cross.',
      'aboutMarkdown':
          'This program trains young volunteers in first aid, disaster response, and community outreach, with opportunities for international deployment.',
      'requirementsMarkdown': '- Age 16+\n- Complete basic first aid training',
      'benefitsMarkdown': '- Certified training\n- Volunteer hours certificate',
      'guidelinesMarkdown':
          '1. Register locally\n2. Complete training modules\n3. Join active deployments',
      'startDate': Timestamp.fromDate(now.subtract(const Duration(days: 10))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 200))),
      'category': 'Volunteering',
      'topic': 'STEM',
      'link': 'https://www.redcross.org',
      'ratingCount': 76,
    },
    {
      'title': 'DAAD Scholarship for Master\'s Study',
      'shortDescription':
          'Full scholarships for international students pursuing a master\'s degree in Germany.',
      'aboutMarkdown':
          'The DAAD offers fully-funded scholarships covering tuition, living expenses, and travel for outstanding students admitted to German universities.',
      'requirementsMarkdown':
          '- Bachelor\'s degree completed\n- Strong academic record\n- German or English proficiency',
      'benefitsMarkdown': '- Full tuition coverage\n- Monthly stipend\n- Health insurance',
      'guidelinesMarkdown':
          '1. Get admitted to a program\n2. Apply through the DAAD portal\n3. Attend an interview',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 90))),
      'category': 'Scholarships',
      'topic': 'STEM',
      'link': 'https://www.daad.de',
      'ratingCount': 210,
    },
    {
      'title': 'NASA High School Internship',
      'shortDescription':
          'A hands-on internship placing high school students in real NASA research teams.',
      'aboutMarkdown':
          'Selected students work directly with NASA scientists and engineers on active research projects, gaining exposure to aerospace engineering and space science.',
      'requirementsMarkdown': '- High school student (US-based)\n- Strong STEM background',
      'benefitsMarkdown': '- Direct NASA mentorship\n- Certificate of completion',
      'guidelinesMarkdown':
          '1. Submit application and essay\n2. Interview\n3. Complete a 6-week placement',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 70))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 35))),
      'category': 'Programs',
      'topic': 'Physics',
      'link': 'https://www.nasa.gov/stem',
      'ratingCount': 165,
    },
    {
      'title': 'Global AI Hackathon 2026',
      'shortDescription':
          'A 48-hour hackathon challenging teams to build AI-powered solutions for real-world problems.',
      'aboutMarkdown':
          'Teams of up to 4 compete over a weekend to design, build, and pitch an AI-driven prototype judged by industry experts.',
      'requirementsMarkdown': '- Team of 1-4\n- Basic programming skills',
      'benefitsMarkdown': '- Cash prizes\n- Mentorship from industry engineers\n- Cloud credits',
      'guidelinesMarkdown':
          '1. Register your team\n2. Attend the kickoff\n3. Submit your project within 48 hours',
      'startDate': Timestamp.fromDate(now.add(const Duration(days: 15))),
      'deadline': Timestamp.fromDate(now.add(const Duration(days: 17))),
      'category': 'Competitions',
      'topic': 'Computer Science',
      'link': 'https://example.com/ai-hackathon',
      'ratingCount': 93,
    },
  ];

  for (final data in sampleData) {
    final docRef = collection.doc(); // auto-generated unique ID
    batch.set(docRef, data);
  }

  await batch.commit();
}