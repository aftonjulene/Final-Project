import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String? displayName;
  final int? age;
  final double? heightCm;
  final double? weightKg;
  final String? goal;
  final String? experienceLevel;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  UserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.age,
    this.heightCm,
    this.weightKg,
    this.goal,
    this.experienceLevel,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'age': age,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goal': goal,
      'experienceLevel': experienceLevel,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null
          ? Timestamp.fromDate(lastLoginAt!)
          : null,
    };
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final createdTs = data['createdAt'] as Timestamp;
    final lastLoginTs = data['lastLoginAt'] as Timestamp?;
    return UserProfile(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: data['displayName'] as String?,
      age: data['age'] as int?,
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      goal: data['goal'] as String?,
      experienceLevel: data['experienceLevel'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: createdTs.toDate(),
      lastLoginAt: lastLoginTs?.toDate(),
    );
  }
}
