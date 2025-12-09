import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  Stream<QuerySnapshot<Map<String, dynamic>>> _feedStream() {
    return FirebaseFirestore.instance
        .collection('workouts')
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _feedStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Could not load feed.'));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No workouts in the feed yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              return _buildFeedCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> data) {
    final userName = (data['userName'] as String?) ?? 'Beast Mode Athlete';
    final goal = data['userGoal'] as String?;
    final title = (data['title'] as String?) ?? 'Workout';
    final notes = (data['notes'] as String?) ?? '';
    final duration = data['durationMinutes'] as int?;

    DateTime date;
    final ts = data['date'];
    if (ts is Timestamp) {
      date = ts.toDate();
    } else {
      date = DateTime.now();
    }

    final dateLabel = '${date.month}/${date.day}/${date.year}';

    String subtitle = dateLabel;
    if (duration != null) {
      subtitle += ' • $duration min';
    }
    if (goal != null && goal.isNotEmpty) {
      subtitle += ' • $goal';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: const Color.fromARGB(52, 174, 174, 174),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // user + date
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'B',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                notes,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 16),
            // placeholders for likes/comments if you want to wire them later
            Row(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 20,
                      color: Colors.red[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: const Color.fromARGB(159, 0, 0, 0),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '0',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
