import 'package:cloud_firestore/cloud_firestore.dart';

class Opportunity {
  final String id; // the Firestore document ID — always useful to keep
  final String title;
  final String shortDescription;
  final String aboutMarkdown;
  final String requirementsMarkdown;
  final String benefitsMarkdown;
  final String guidelinesMarkdown;
  final DateTime deadline;
  final String category;
  final String topic;
  final String link;
  final int ratingCount;


  Opportunity({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.aboutMarkdown,
    required this.requirementsMarkdown,
    required this.benefitsMarkdown,
    required this.guidelinesMarkdown,
    required this.deadline,
    required this.category,
    required this.topic,
    required this.link,
    required this.ratingCount,
  });

  factory Opportunity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Opportunity(
      id: doc.id,
      title: data['title'] ?? '',
      shortDescription: data['shortDescription'] ?? '',
      aboutMarkdown: data['aboutMarkdown'] ?? '',
      requirementsMarkdown: data['requirementsMarkdown'] ?? '',
      benefitsMarkdown: data['benefitsMarkdown'] ?? '',
      guidelinesMarkdown: data['guidelinesMarkdown'] ?? '',
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] ?? '',
      topic: data['topic'] ?? '',
      link: data['link'] ?? '',
      ratingCount: (data['ratingCount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}