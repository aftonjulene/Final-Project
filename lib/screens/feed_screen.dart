import 'package:flutter/material.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mock feed data
    final List<Map<String, dynamic>> feedPosts = [
      {
        'user': 'Alex Chen',
        'time': '2 hours ago',
        'workout': 'Morning Run',
        'details': '5km in 28 minutes',
        'likes': 12,
        'comments': 3,
      },
      {
        'user': 'Sarah Martinez',
        'time': '2 hours ago',
        'workout': 'Leg Day',
        'details': '6 exercises • 45 minutes',
        'likes': 24,
        'comments': 7,
      },
      {
        'user': 'Mike Johnson',
        'time': '2 hours ago',
        'workout': 'Upper Body',
        'details': 'Bench press PR: 100kg!',
        'likes': 45,
        'comments': 12,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Feed',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: feedPosts.length,
        itemBuilder: (context, index) {
          return _buildFeedCard(feedPosts[index]);
        },
      ),
      // Bottom navigation removed - handled by MainNavigation
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[300],
                  child: Text(
                    post['user'][0],
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
                        post['user'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        post['time'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Workout details
            Text(
              post['workout'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              post['details'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            // Like and comment buttons
            Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_border, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${post['likes']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '${post['comments']}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
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