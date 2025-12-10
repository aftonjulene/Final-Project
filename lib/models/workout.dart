import 'package:cloud_firestore/cloud_firestore.dart';
import 'exercise.dart';

class Workout {
  final String id;
  final String userId;
  final String title;
  final DateTime date;
  final int? durationMinutes;
  final List<Exercise> exercises;
  final bool userIsPrivate;

  Workout({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    this.durationMinutes,
    required this.exercises,
    this.userIsPrivate = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'date': Timestamp.fromDate(date),
      'durationMinutes': durationMinutes,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'userIsPrivate': userIsPrivate,
    };
  }

  factory Workout.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final dateTs = data['date'] as Timestamp;
    final rawExercises = (data['exercises'] as List?) ?? [];

    return Workout(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      date: dateTs.toDate(),
      durationMinutes: data['durationMinutes'] as int?,
      exercises: rawExercises
          .map((e) => Exercise.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      userIsPrivate: data['userIsPrivate'] as bool? ?? false,
    );
  }
}
