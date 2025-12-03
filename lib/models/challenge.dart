import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final bool isPublic;
  final DateTime startDate;
  final DateTime endDate;
  final String? goalType;
  final double? goalValue;

  Challenge({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.isPublic,
    required this.startDate,
    required this.endDate,
    this.goalType,
    this.goalValue,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'isPublic': isPublic,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'goalType': goalType,
      'goalValue': goalValue,
    };
  }

  factory Challenge.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final startTs = data['startDate'] as Timestamp;
    final endTs = data['endDate'] as Timestamp;

    return Challenge(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      ownerId: data['ownerId'] as String,
      isPublic: (data['isPublic'] as bool?) ?? true,
      startDate: startTs.toDate(),
      endDate: endTs.toDate(),
      goalType: data['goalType'] as String?,
      goalValue: (data['goalValue'] as num?)?.toDouble(),
    );
  }
}
