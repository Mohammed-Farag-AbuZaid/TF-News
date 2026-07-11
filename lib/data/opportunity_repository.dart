import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tf_news/data/opportunity_model.dart';

class OpportunityRepository {
  final CollectionReference _opportunitiesRef =
      FirebaseFirestore.instance.collection('opportunities');

  Future<List<Opportunity>> getOpportunities({
    String? category,
    String? topic,
  }) async {
    Query query = _opportunitiesRef;

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (topic != null && topic.isNotEmpty) {
      query = query.where('topic', isEqualTo: topic);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => Opportunity.fromFirestore(doc)).toList();
  }
}