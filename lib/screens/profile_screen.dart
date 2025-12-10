import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../models/user_profile.dart';
import '../widgets/stat_card.dart';
import 'edit_profile_screen.dart';
import 'photo_journal_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final auth = AuthService();

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      await auth.signOut();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final workoutsStream = FirebaseFirestore.instance
        .collection('workouts')
        .where('userId', isEqualTo: user.uid)
        .snapshots();
    final challengesStream = FirebaseFirestore.instance
        .collection('challengeParticipants')
        .where('userId', isEqualTo: user.uid)
        .where('completed', isEqualTo: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Profile not found'));
          }

          final data = snapshot.data!.data()!;
          final profile = UserProfile.fromDoc(snapshot.data!);

          final initials = (profile.displayName ?? profile.email)
              .trim()
              .split(RegExp(r'\s+'))
              .where((p) => p.isNotEmpty)
              .map((p) => p[0].toUpperCase())
              .take(2)
              .join();

          final handle =
              (profile.username != null && profile.username!.trim().isNotEmpty)
              ? '@${profile.username!.trim()}'
              : '@${profile.email.split('@').first}';

          final goalText = profile.goal ?? 'No goal set yet';

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage:
                        profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                        ? NetworkImage(profile.photoUrl!)
                        : null,
                    child:
                        (profile.photoUrl == null || profile.photoUrl!.isEmpty)
                        ? Text(
                            initials.isEmpty ? 'BM' : initials,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a1d2e),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.displayName?.isNotEmpty == true
                        ? profile.displayName!
                        : profile.email,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    handle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    goalText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF1a1d2e)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Color(0xFF1a1d2e),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: workoutsStream,
                    builder: (context, workoutSnap) {
                      final workouts = workoutSnap.data?.docs ?? [];
                      final workoutCount = workouts.length;
                      final streak = _calculateStreak(workouts);

                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: challengesStream,
                        builder: (context, challengeSnap) {
                          final challengesDocs = challengeSnap.data?.docs ?? [];
                          final challengesCompleted = challengesDocs.length;

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              SimpleStatCard(
                                value: workoutCount.toString(),
                                label: 'Workouts',
                              ),
                              SimpleStatCard(
                                value: streak.toString(),
                                label: 'Day Streak',
                              ),
                              SimpleStatCard(
                                value: challengesCompleted.toString(),
                                label: 'Challenges',
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildMenuButton(
                    icon: Icons.photo_library,
                    title: 'Photo Journal',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PhotoJournalScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuButton(
                    icon: Icons.settings,
                    title: 'Settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildMenuButton(
                    icon: Icons.logout,
                    title: 'Logout',
                    onTap: () {
                      _handleLogout(context);
                    },
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _calculateStreak(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> workouts,
  ) {
    if (workouts.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final workoutDates =
        workouts
            .map((doc) {
              final ts = doc.data()['date'];
              if (ts is! Timestamp) return null;
              final date = ts.toDate();
              return DateTime(date.year, date.month, date.day);
            })
            .whereType<DateTime>()
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (workoutDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = today;

    if (workoutDates.first.isBefore(today)) {
      checkDate = today.subtract(const Duration(days: 1));
    }

    for (final workoutDate in workoutDates) {
      if (workoutDate.isAtSameMomentAs(checkDate) ||
          workoutDate.isAfter(checkDate)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    const primary = Color(0xFF1a1d2e);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? const Color.fromARGB(129, 244, 67, 54)
                : Colors.grey[300]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDestructive ? Colors.red : Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? Colors.red : primary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red : Colors.grey[600],
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
