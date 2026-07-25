import 'package:flutter/material.dart';
import 'package:tf_news/data/opportunity_model.dart';
import 'package:tf_news/data/opportunity_repository.dart';
import 'package:tf_news/pages/widgets/nav_bar.dart';
import 'package:tf_news/pages/widgets/opportunities_header.dart';
import 'package:tf_news/pages/widgets/opportunity_card.dart';
import 'package:tf_news/pages/widgets/status_filter.dart';
import 'package:tf_news/pages/widgets/topic_related_filter.dart';

class HomeScreen extends StatefulWidget {
  final String initialCategory;
  const HomeScreen({super.key, this.initialCategory = 'All'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final OpportunityRepository _repository = OpportunityRepository();

  late String? _selectedCategory;
  String? _selectedTopic;
  String _selectedStatus = 'Active';

  late Future<List<Opportunity>> _opportunitiesFuture;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory == 'All' ? null : widget.initialCategory;
    _opportunitiesFuture = _fetchOpportunities();
  }

  Future<List<Opportunity>> _fetchOpportunities() {
    return _repository.getOpportunities(
      category: _selectedCategory == 'Must-know' ? null : _selectedCategory,
      topic: _selectedTopic,
      mustKnow: _selectedCategory == 'Must-know' ? true : null,
    );
  }

  void _refetch() {
    setState(() {
      _opportunitiesFuture = _fetchOpportunities();
    });
  }

  void _onCategorySelected(String category) {
    _selectedCategory = category == 'All' ? null : category;
    _refetch();
  }

  void _onTopicSelected(String topic) {
    _selectedTopic = topic == 'All Opportunities' ? null : topic;
    _refetch();
  }

  void _onStatusSelected(String status) {
    setState(() {
      _selectedStatus = status;
    });
  }

  List<Opportunity> _applyStatusFilter(List<Opportunity> opportunities) {
    final now = DateTime.now();

    switch (_selectedStatus) {
      case 'Active':
        return opportunities
            .where((o) => o.startDate.isBefore(now) && o.deadline.isAfter(now))
            .toList();
      case 'Ended':
        return opportunities.where((o) => o.deadline.isBefore(now)).toList();
      case 'Upcoming':
        return opportunities.where((o) => o.startDate.isAfter(now)).toList();
      case 'Most Popular':
        final sorted = [...opportunities];
        sorted.sort((a, b) => b.ratingCount.compareTo(a.ratingCount));
        return sorted;
      default:
        return opportunities;
    }
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
              initialCategory: widget.initialCategory,
              onCategorySelected: _onCategorySelected,
            ),
            const Divider(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    TopicRelatedFilter(onFilterSelected: _onTopicSelected),
                    const SizedBox(height: 16),
                    StatusFilter(onFilterSelected: _onStatusSelected),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const OpportunitiesHeader(),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Opportunity>>(
                        future: _opportunitiesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (snapshot.hasError) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text('Something went wrong: ${snapshot.error}'),
                              ),
                            );
                          }

                          final opportunities = _applyStatusFilter(snapshot.data ?? []);

                          if (opportunities.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: Text('No opportunities found')),
                            );
                          }

                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
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