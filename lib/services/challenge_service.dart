import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/workout.dart';
import '../models/challenge.dart';
import '../models/challenge_participant.dart';

class ChallengeService {
  final FirebaseFirestore firestore;

  ChallengeService({FirebaseFirestore? firestore})
    : firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> updateChallengesForWorkout({
    required Workout workout,
    required String userId,
  }) async {
    try {
      final dateOnly = DateTime(
        workout.date.year,
        workout.date.month,
        workout.date.day,
      );

      int workoutSets = 0;
      int workoutReps = 0;
      final int workoutMinutes = workout.durationMinutes ?? 0;

      final Map<String, int> repsByExerciseName = {};

      for (final ex in workout.exercises) {
        workoutSets += ex.sets;

        final totalRepsForExercise = ex.sets * ex.reps;
        workoutReps += totalRepsForExercise;

        final key = ex.name.trim();
        repsByExerciseName[key] =
            (repsByExerciseName[key] ?? 0) + totalRepsForExercise;
      }

      final participantSnap = await firestore
          .collection('challengeParticipants')
          .where('userId', isEqualTo: userId)
          .get();

      if (participantSnap.docs.isEmpty) return;

      final activeParticipantDocs = participantSnap.docs.where((doc) {
        final data = doc.data();
        final completed = (data['completed'] as bool?) ?? false;
        return !completed;
      }).toList();

      if (activeParticipantDocs.isEmpty) return;

      final challengeIds = activeParticipantDocs
          .map((d) => d.data()['challengeId'] as String)
          .toSet()
          .toList();

      if (challengeIds.isEmpty) return;

      final challengesSnap = await firestore
          .collection('challenges')
          .where(FieldPath.documentId, whereIn: challengeIds)
          .get();

      final Map<String, Challenge> challengesById = {
        for (final doc in challengesSnap.docs) doc.id: Challenge.fromDoc(doc),
      };

      final now = DateTime.now();

      for (final participantDoc in activeParticipantDocs) {
        final participant = ChallengeParticipant.fromDoc(participantDoc);
        final challenge = challengesById[participant.challengeId];
        if (challenge == null) continue;
        if (!challenge.isActive) continue;

        if (now.isBefore(challenge.startDate) ||
            now.isAfter(challenge.endDate)) {
          continue;
        }

        final String? goalType = challenge.goalType;
        final double? target = challenge.goalValue;
        if (goalType == null || target == null) continue;

        double newProgress = participant.progressValue;
        DateTime? newLastUpdated = participant.lastUpdated;
        final bool wasCompletedBefore = participant.completed;
        bool completedNow = participant.completed;

        switch (goalType) {
          case 'STREAK_DAYS':
            {
              final last = participant.lastUpdated;
              int currentStreak = participant.progressValue.round();

              if (last == null) {
                currentStreak = 1;
              } else {
                final lastDateOnly = DateTime(last.year, last.month, last.day);
                final diffDays = dateOnly.difference(lastDateOnly).inDays;

                if (diffDays == 0) {
                  // already counted this day
                } else if (diffDays == 1) {
                  currentStreak = currentStreak + 1;
                } else if (diffDays > 1) {
                  currentStreak = 1;
                } else {
                  // backdated workout, ignore for streak
                }
              }

              newProgress = currentStreak.toDouble();
              newLastUpdated = dateOnly;
            }
            break;

          case 'TOTAL_SETS':
            {
              newProgress = participant.progressValue + workoutSets;
              newLastUpdated = now;
            }
            break;

          case 'TOTAL_REPS':
            {
              newProgress = participant.progressValue + workoutReps;
              newLastUpdated = now;
            }
            break;

          case 'TOTAL_MINUTES':
            {
              newProgress =
                  participant.progressValue + workoutMinutes.toDouble();
              newLastUpdated = now;
            }
            break;

          case 'EXERCISE_REPS':
            {
              final exerciseName = challenge.exerciseName?.trim();
              if (exerciseName != null && exerciseName.isNotEmpty) {
                final repsForThisExercise =
                    repsByExerciseName[exerciseName] ?? 0;
                if (repsForThisExercise > 0) {
                  newProgress = participant.progressValue + repsForThisExercise;
                  newLastUpdated = now;
                }
              }
            }
            break;

          default:
            break;
        }

        if (newProgress >= target) {
          completedNow = true;
        }

        await participantDoc.reference.update({
          'progressValue': newProgress,
          'completed': completedNow,
          'lastUpdated': newLastUpdated != null
              ? Timestamp.fromDate(newLastUpdated)
              : participant.lastUpdated != null
              ? Timestamp.fromDate(participant.lastUpdated!)
              : null,
        });

        if (completedNow && !wasCompletedBefore) {
          await _handleChallengeCompleted(userId: userId, challenge: challenge);
        }
      }
    } catch (e) {
      // don't break workout saving just because challenge logic failed
      print('updateChallengesForWorkout error: $e');
    }
  }

  Future<void> _handleChallengeCompleted({
    required String userId,
    required Challenge challenge,
  }) async {
    try {
      final ladderKey = challenge.ladderKey;
      final goalType = challenge.goalType;
      final currentTarget = challenge.goalValue;

      if (ladderKey == null || goalType == null || currentTarget == null) {
        return;
      }

      final ladderSnap = await firestore
          .collection('challenges')
          .where('ladderKey', isEqualTo: ladderKey)
          .where('goalType', isEqualTo: goalType)
          .where('isActive', isEqualTo: true)
          .get();

      Challenge? nextChallenge;
      for (final doc in ladderSnap.docs) {
        final ch = Challenge.fromDoc(doc);
        if (ch.goalValue == null) continue;
        if (ch.goalValue! <= currentTarget) continue;
        if (nextChallenge == null ||
            ch.goalValue! < (nextChallenge.goalValue ?? double.infinity)) {
          nextChallenge = ch;
        }
      }

      if (nextChallenge == null) {
        return;
      }

      final now = DateTime.now();
      await firestore.collection('challengeParticipants').add({
        'challengeId': nextChallenge.id,
        'userId': userId,
        'progressValue': 0.0,
        'completed': false,
        'joinedAt': Timestamp.fromDate(now),
        'lastUpdated': null,
      });

      // later: hook in badges / social feed here
    } catch (e) {
      print('_handleChallengeCompleted error: $e');
    }
  }
}

Future<void> leaveChallenge({
  required String challengeId,
  required String userId,
}) async {
  final ref = FirebaseFirestore.instance
      .collection('challengeParticipants')
      .where('userId', isEqualTo: userId)
      .where('challengeId', isEqualTo: challengeId);

  final snap = await ref.get();

  for (final doc in snap.docs) {
    await doc.reference.delete();
  }
}
