import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tf_news/data/opportunity_model.dart';

class OpportunityRepository{
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

    if (!doc.exists) {
      return null;
    }
    return Opportunity.fromFirestore(doc);
  }
  /// count the opportuniteis number
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