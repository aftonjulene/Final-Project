import 'package:cloud_firestore/cloud_firestore.dart';

class JournalEntry {
  final String id;
  final String userId;
  final String? workoutId;
  final String? imageUrl;
  final String? caption;
  final bool isPrivate;
  final DateTime createdAt;

  JournalEntry({
    required this.id,
    required this.userId,
    this.workoutId,
    this.imageUrl,
    this.caption,
    required this.isPrivate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'workoutId': workoutId,
      'imageUrl': imageUrl,
      'caption': caption,
      'isPrivate': isPrivate,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory JournalEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final createdTs = data['createdAt'] as Timestamp;
    return JournalEntry(
      id: doc.id,
      userId: data['userId'] as String,
      workoutId: data['workoutId'] as String?,
      imageUrl: data['imageUrl'] as String?,
      caption: data['caption'] as String?,
      isPrivate: (data['isPrivate'] as bool?) ?? false,
      createdAt: createdTs.toDate(),
    );
  }
}
