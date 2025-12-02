import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeParticipant {
  final String id;
  final String challengeId;
  final String userId;
  final double progressValue;
  final bool completed;
  final DateTime joinedAt;
  final DateTime? lastUpdated;

  ChallengeParticipant({
    required this.id,
    required this.challengeId,
    required this.userId,
    required this.progressValue,
    required this.completed,
    required this.joinedAt,
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'challengeId': challengeId,
      'userId': userId,
      'progressValue': progressValue,
      'completed': completed,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
    };
  }

  factory ChallengeParticipant.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final joinedTs = data['joinedAt'] as Timestamp;
    final lastUpdatedTs = data['lastUpdated'] as Timestamp?;

    return ChallengeParticipant(
      id: doc.id,
      challengeId: data['challengeId'] as String,
      userId: data['userId'] as String,
      progressValue: (data['progressValue'] as num).toDouble(),
      completed: (data['completed'] as bool?) ?? false,
      joinedAt: joinedTs.toDate(),
      lastUpdated: lastUpdatedTs?.toDate(),
    );
  }
}
