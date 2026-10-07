import 'package:flutter/material.dart';
import 'package:tf_news/data/opportunity_model.dart';
import 'package:tf_news/data/opportunity_repository.dart';
import 'package:tf_news/data/opportunity_section.dart';
import 'package:tf_news/pages/widgets/nav_bar.dart';
import 'package:tf_news/pages/widgets/opportunities_header.dart';
import 'package:tf_news/pages/widgets/opportunity_card.dart';
import 'package:tf_news/pages/widgets/status_filter.dart';
import 'package:tf_news/pages/widgets/topic_related_filter.dart';

class OpportunitiesPage extends StatefulWidget {
  final OpportunitySection section;
  final String initialCategory;
  const OpportunitiesPage({
    super.key,
    required this.section,
    this.initialCategory = 'All',
  });

  @override
  State<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends State<OpportunitiesPage> {
  final OpportunityRepository _repository = OpportunityRepository();

  String? _selectedCategory;
  String? _selectedTopic;
  String _selectedStatus = 'Open now';
  late Future<List<Opportunity>> _opportunitiesFuture;

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory == 'All' ? null : widget.initialCategory;
    _opportunitiesFuture = _fetchOpportunities();
  }

  Future<List<Opportunity>> _fetchOpportunities() {
    final isMustKnow = _selectedCategory == OpportunitySection.mustKnow;
    return _repository.getOpportunities(
      section: widget.section.id,
      category: isMustKnow ? null : _selectedCategory,
      topic: _selectedTopic,
      mustKnow: isMustKnow ? true : null,
    );
  }

  void _refetch() {
    setState(() {
      _opportunitiesFuture = _fetchOpportunities();
    });
  }

  void _onCategorySelected(String category) {
    _selectedCategory = category == 'All' ? null : category;
    _selectedTopic = null; 
    _refetch();
  }

  void _onTopicSelected(String topic) {
    _selectedTopic = topic == OpportunitySection.allTopics ? null : topic;
    _refetch();
  }

  void _onStatusSelected(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  List<Opportunity> _applyStatusFilter(List<Opportunity> opportunities) {
    final now = DateTime.now();

    bool isOpen(Opportunity o) =>
        !o.startDate.isAfter(now) && !o.deadline.isBefore(now);

    if (_selectedStatus == 'Upcoming') {
      return opportunities.where((o) => !isOpen(o)).toList()
        ..sort((a, b) => _nextOpening(a, now).compareTo(_nextOpening(b, now)));
    }

    return opportunities.where(isOpen).toList()
      ..sort((a, b) => a.deadline.compareTo(b.deadline));
  }

  DateTime _nextOpening(Opportunity o, DateTime now) {
    var d = o.startDate;
    while (!d.isAfter(now)) {
      d = DateTime(d.year + 1, d.month, d.day);
    }
    return d;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            NavBar(
              categories: widget.section.categories,
              initialCategory: widget.initialCategory,
              onCategorySelected: _onCategorySelected,
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    TopicRelatedFilter(
                      key: ValueKey('${widget.section.id}-$_selectedCategory'),
                      title: widget.section.topicsLabel,
                      topics: widget.section.topicsFor(_selectedCategory),
                      onFilterSelected: _onTopicSelected,
                    ),
                    const SizedBox(height: 16),
                    StatusFilter(onFilterSelected: _onStatusSelected),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OpportunitiesHeader(title: widget.section.title),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Opportunity>>(
                        future: _opportunitiesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                    'Something went wrong: ${snapshot.error}'),
                              ),
                            );
                          }

                          final opportunities =
                              _applyStatusFilter(snapshot.data ?? []);

                          if (opportunities.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child:
                                  Center(child: Text('No opportunities found')),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 500,
                              mainAxisExtent: 300,
                              crossAxisSpacing: 35,
                              mainAxisSpacing: 35,
                            ),
                            itemCount: opportunities.length,
                            itemBuilder: (context, index) => OpportunityCard(
                              opportunity: opportunities[index],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}