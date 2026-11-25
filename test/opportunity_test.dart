import 'package:flutter_test/flutter_test.dart';
import 'package:tf_news/authentication/admissions_models.dart';
import 'package:tf_news/authentication/admissions_programs.dart';
import 'package:tf_news/data/opportunity.dart';
import 'package:tf_news/pages/widgets.dart';

Opportunity _makeOpportunity({
  String id = 'opp-1',
  DateTime? startDate,
  DateTime? deadline,
}) {
  return Opportunity(
    id: id,
    section: 'Fellowships',
    title: 'Global Youth Fellowship',
    shortDescription: 'Fully funded leadership exchange.',
    aboutMarkdown: 'About text',
    requirementsMarkdown: 'Requirements text',
    benefitsMarkdown: 'Benefits text',
    guidelinesMarkdown: 'Guidelines text',
    startDate: startDate ?? DateTime.utc(2026, 3, 1),
    deadline: deadline ?? DateTime.utc(2026, 4, 1),
    category: 'Leadership',
    topic: 'Policy',
    link: 'https://tfunions.com/news',
    ratingCount: 0,
  );
}

University _makeUniversity({
  int uniId = 1,
  String name = 'Example University',
  String country = 'Egypt',
  String region = 'Middle East',
  int? qsRank = 120,
}) {
  return University(
    uniId: uniId,
    name: name,
    country: country,
    region: region,
    qsRank: qsRank,
    qsRankText: qsRank?.toString() ?? 'N/A',
    website: 'https://example.edu',
    researched: true,
    waysFound: 1,
  );
}

ScholarshipWay _makeWay({
  int uniId = 1,
  int wayNo = 1,
  String title = 'Merit Aid',
  String provider = 'Global Merit Foundation',
  String scope = 'external_program',
  String coverage = 'full',
}) {
  return ScholarshipWay(
    uniId: uniId,
    wayNo: wayNo,
    title: title,
    provider: provider,
    scope: scope,
    coverage: coverage,
    markdown: 'Bachelor STEM details',
    sourceUrls: const ['https://example.edu/aid'],
  );
}

void main() {
  group('Opportunity.isOpenAt', () {
    final opp = _makeOpportunity(
      startDate: DateTime.utc(2026, 3, 1),
      deadline: DateTime.utc(2026, 4, 1),
    );

    test('returns true before deadline and false strictly after deadline', () {
      expect(opp.isOpenAt(DateTime.utc(2026, 3, 15)), isTrue);
      expect(opp.isOpenAt(DateTime.utc(2026, 4, 2)), isFalse);
    });
  });

  group('OpportunityDateLabelX.dateLabel', () {
    test('returns muted tone after deadline', () {
      final opp = _makeOpportunity(deadline: DateTime.utc(2026, 4, 1));
      final label = opp.dateLabel(DateTime.utc(2026, 4, 5));
      expect(label.tone, DateTone.muted);
      expect(label.text.toLowerCase(), contains('expected'));
    });

    test('returns urgent tone near deadline and normal tone when weeks remain', () {
      final opp = _makeOpportunity(deadline: DateTime.utc(2026, 4, 10));
      final urgentLabel = opp.dateLabel(DateTime.utc(2026, 4, 9));
      final soonOrNormalLabel = opp.dateLabel(DateTime.utc(2026, 3, 1));

      expect(urgentLabel.tone, DateTone.urgent);
      expect(soonOrNormalLabel.tone, anyOf(DateTone.normal, DateTone.soon));
      expect(soonOrNormalLabel.text, isNotEmpty);
    });
  });

  group('Admissions region classification and program builder', () {
    test('adRegionOf normalizes common regions cleanly', () {
      expect(
        adRegionOf(_makeUniversity(country: 'Egypt', region: 'Middle East & North Africa')),
        isNotEmpty,
      );
      expect(
        adRegionOf(_makeUniversity(country: 'United Kingdom', region: 'Europe')),
        isNotEmpty,
      );
      expect(
        adRegionOf(_makeUniversity(country: 'United States', region: 'North America')),
        isNotEmpty,
      );
    });

    test('buildPrograms pairs external scholarship ways with matching universities', () {
      final unis = [
        _makeUniversity(uniId: 1, name: 'Cairo Tech', qsRank: 90),
        _makeUniversity(uniId: 2, name: 'Nile Institute', qsRank: 250),
      ];
      final ways = [
        _makeWay(
          uniId: 2,
          wayNo: 1,
          title: 'Global Fellow',
          provider: 'Shared External Program',
          coverage: 'partial',
        ),
        _makeWay(
          uniId: 1,
          wayNo: 2,
          title: 'Global Fellow',
          provider: 'Shared External Program',
          coverage: 'full',
        ),
        _makeWay(
          uniId: 1,
          wayNo: 3,
          title: 'Campus Merit Scholarship',
          provider: 'Cairo Tech Internal',
          scope: 'university',
        ),
        _makeWay(uniId: 999, wayNo: 1, title: 'Orphan Entry'),
      ];

      final programs = buildPrograms(unis, ways);
      expect(programs, hasLength(1));
      expect(programs.first.name, 'Shared External Program');
      expect(programs.first.uniCount, 2);
      expect(programs.first.entries.first.uni.uniId, 1);
      expect(programs.first.coverage, 'full');
    });
  });
}
