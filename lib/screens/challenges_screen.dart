import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/challenge.dart';
import '../models/challenge_participant.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _challengesStream() {
    return FirebaseFirestore.instance
        .collection('challenges')
        .orderBy('startDate', descending: false)
        .snapshots();
  }

  Future<void> _joinChallenge(Challenge challenge) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final participantRef = FirebaseFirestore.instance
        .collection('challenges')
        .doc(challenge.id)
        .collection('participants')
        .doc(user.uid);

    final participant = ChallengeParticipant(
      id: user.uid,
      challengeId: challenge.id,
      userId: user.uid,
      progressValue: 0.0,
      completed: false,
      joinedAt: now,
      // Important: null so the first workout sets the streak correctly.
      lastUpdated: null,
    );

    await participantRef.set(participant.toMap());
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view challenges.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Challenges',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _challengesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('No challenges available right now.'),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No challenges have been created yet.'),
            );
          }

          final challenges = docs.map((d) => Challenge.fromDoc(d)).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: challenges
                  .map(
                    (challenge) =>
                        _buildChallengeCard(context, user.uid, challenge),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChallengeCard(
    BuildContext context,
    String uid,
    Challenge challenge,
  ) {
    final start = challenge.startDate;
    final end = challenge.endDate;
    final range = '${start.month}/${start.day} - ${end.month}/${end.day}';

    final participantDocStream = FirebaseFirestore.instance
        .collection('challenges')
        .doc(challenge.id)
        .collection('participants')
        .doc(uid)
        .snapshots();

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: participantDocStream,
      builder: (context, snapshot) {
        ChallengeParticipant? participant;
        if (snapshot.hasData && snapshot.data!.exists) {
          participant = ChallengeParticipant.fromDoc(snapshot.data!);
        }

        final joined = participant != null;
        final rawProgress = participant?.progressValue ?? 0.0;
        final target = challenge.goalValue ?? 0.0;

        double fraction = 0.0;
        if (target > 0) {
          fraction = (rawProgress / target).clamp(0.0, 1.0);
        }

        final percent = (fraction * 100).round().clamp(0, 100);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.emoji_events,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          challenge.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          range,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: Colors.grey[200],
                  color: const Color(0xFF1a1d2e),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$percent% complete',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    joined
                        ? (participant!.completed ? 'Completed' : 'In progress')
                        : 'Not joined',
                    style: TextStyle(
                      fontSize: 14,
                      color: joined
                          ? (participant!.completed
                                ? Colors.green
                                : Colors.grey[600])
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: joined
                      ? null
                      : () {
                          _joinChallenge(challenge);
                        },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF1a1d2e)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    joined ? 'Joined' : 'Join Challenge',
                    style: TextStyle(
                      color: joined ? Colors.grey : const Color(0xFF1a1d2e),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
