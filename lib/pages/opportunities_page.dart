// lib/pages/opportunities_page.dart
import 'package:flutter/material.dart';
import 'package:tf_news/data/opportunity.dart';
import 'package:tf_news/pages/widgets.dart';

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

  OpportunityStatus get _status => _selectedStatus == 'Upcoming'
      ? OpportunityStatus.upcoming
      : OpportunityStatus.open;

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
    _selectedTopic = null; // topics change with the tab, so reset the choice
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
                      // new key = fresh selection whenever the tab changes
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
                              (snapshot.data ?? []).forStatus(_status);

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