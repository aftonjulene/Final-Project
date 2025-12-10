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

  final bool privateProfile;
  final bool pushNotifications;
  final bool workoutReminders;
  final bool socialUpdates;
  final bool showStats;

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
    this.privateProfile = false,
    this.pushNotifications = true,
    this.workoutReminders = false,
    this.socialUpdates = true,
    this.showStats = true,
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

      // NEW: persist settings + privacy
      'privateProfile': privateProfile,
      'pushNotifications': pushNotifications,
      'workoutReminders': workoutReminders,
      'socialUpdates': socialUpdates,
      'showStats': showStats,
    };
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final createdTs = data['createdAt'] as Timestamp;
    final lastLoginTs = data['lastLoginAt'] as Timestamp?;

    return UserProfile(
      uid: data['uid'] as String,
      email: data['email'] as String,
      displayName: (data['displayName'] ?? data['name']) as String?,
      age: data['age'] as int?,
      heightCm: (data['heightCm'] as num?)?.toDouble(),
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      goal: data['goal'] as String?,
      experienceLevel: data['experienceLevel'] as String?,
      photoUrl: data['photoUrl'] as String?,
      createdAt: createdTs.toDate(),
      lastLoginAt: lastLoginTs?.toDate(),

      privateProfile: data['privateProfile'] as bool? ?? false,
      pushNotifications: data['pushNotifications'] as bool? ?? true,
      workoutReminders: data['workoutReminders'] as bool? ?? false,
      socialUpdates: data['socialUpdates'] as bool? ?? true,
      showStats: data['showStats'] as bool? ?? true,
    );
  }
}
