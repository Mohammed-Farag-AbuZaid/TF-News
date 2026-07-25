import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tf_news/authentication/controllers/user_controller.dart';
import 'package:tf_news/data/opportunity_model.dart';
import 'package:tf_news/utils/constants/colors.dart';

class OpportunityCard extends StatefulWidget {
  final Opportunity opportunity;

  const OpportunityCard({super.key, required this.opportunity});

  @override
  State<OpportunityCard> createState() => _OpportunityCardState();
}

class _OpportunityCardState extends State<OpportunityCard> {
  late bool _hasVoted;
  late int _ratingCount;
  bool _voting = false;

  @override
  void initState() {
    super.initState();
    final uid = UserController.instance.user.value.id;
    _ratingCount = widget.opportunity.ratingCount;
    _hasVoted = widget.opportunity.voters.contains(uid);
  }

  Future<void> _toggleVote() async {
    if (_voting) return;
    final uid = UserController.instance.user.value.id;
    if (uid.isEmpty) return;
    setState(() => _voting = true);
    final ref = FirebaseFirestore.instance
        .collection('opportunities')
        .doc(widget.opportunity.id);
    try {
      if (_hasVoted) {
        await ref.update({
          'ratingCount': FieldValue.increment(-1),
          'voters': FieldValue.arrayRemove([uid]),
        });
        setState(() { _hasVoted = false; _ratingCount--; });
      } else {
        await ref.update({
          'ratingCount': FieldValue.increment(1),
          'voters': FieldValue.arrayUnion([uid]),
        });
        setState(() { _hasVoted = true; _ratingCount++; });
      }
    } catch (_) {
      Get.snackbar('Error', 'Could not register your vote.',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _voting = false);
    }
  }

  String _deadlineText() {
    final diff = widget.opportunity.deadline.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Deadline passed';
    if (diff == 0) return 'Today';
    if (diff == 1) return '1 day left';
    return '$diff days left';
  }

  Color _deadlineColor() {
    final diff = widget.opportunity.deadline.difference(DateTime.now()).inDays;
    if (diff < 0) return Colors.grey[400]!;
    if (diff <= 3) return const Color(0xFFD64045);
    if (diff <= 7) return const Color(0xFFE07B39);
    return const Color(0xFF2E7D32);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: category + must-know + vote
            Row(
              children: [
                Text(
                  widget.opportunity.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: TColors.primary,
                    letterSpacing: 0.9,
                  ),
                ),
                if (widget.opportunity.mustKnow) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'MUST-KNOW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                      letterSpacing: 0.9,
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _toggleVote,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _voting
                          ? SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.amber[600],
                              ),
                            )
                          : Icon(
                              _hasVoted
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: _hasVoted
                                  ? Colors.amber[600]
                                  : Colors.grey[400],
                            ),
                      const SizedBox(width: 3),
                      Text(
                        '$_ratingCount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _hasVoted
                              ? Colors.amber[700]
                              : Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),
            Container(height: 1, color: Colors.grey[100]),
            const SizedBox(height: 12),

            // Title
            Text(
              widget.opportunity.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 6),

            // Description — fills remaining space
            Expanded(
              child: Text(
                widget.opportunity.shortDescription,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                  height: 1.55,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            // Deadline + topic
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 12, color: _deadlineColor()),
                const SizedBox(width: 4),
                Text(
                  _deadlineText(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _deadlineColor(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.opportunity.topic,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Explore button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Get.toNamed('/opportunity/${widget.opportunity.id}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: TColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  'Explore',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}