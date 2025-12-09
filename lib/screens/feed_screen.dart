import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Stream<QuerySnapshot<Map<String, dynamic>>> _feedStream() {
    return FirebaseFirestore.instance
        .collection('workouts')
        .orderBy('date', descending: true)
        .limit(30)
        .snapshots();
  }

  Future<void> _toggleLike(String workoutId, List<dynamic> currentLikes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likes = List<String>.from(currentLikes.map((e) => e.toString()));
    final isLiked = likes.contains(user.uid);

    if (isLiked) {
      likes.remove(user.uid);
    } else {
      likes.add(user.uid);
    }

    try {
      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(workoutId)
          .update({'likes': likes});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _addComment(String workoutId, String commentText) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || commentText.trim().isEmpty) return;

    try {
      // Get user profile for display name
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['displayName'] as String? ??
          user.email ??
          'Anonymous';

      // Simple add without batch to avoid stream conflicts
      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(workoutId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'userName': userName,
        'text': commentText.trim(),
        'likes': <String>[],
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleCommentLike(
      String workoutId, String commentId, List<dynamic> currentLikes) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get the workout to check if user is the post owner
    final workoutDoc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(workoutId)
        .get();
    final workoutUserId = workoutDoc.data()?['userId'] as String?;

    // Only post owner can like comments
    if (workoutUserId != user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Only the post owner can like comments.')),
        );
      }
      return;
    }

    final likes = List<String>.from(currentLikes.map((e) => e.toString()));
    final isLiked = likes.contains(user.uid);

    if (isLiked) {
      likes.remove(user.uid);
    } else {
      likes.add(user.uid);
    }

    try {
      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(workoutId)
          .collection('comments')
          .doc(commentId)
          .update({'likes': likes});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showCommentsDialog(String workoutId, String postOwnerId) {
    final user = FirebaseAuth.instance.currentUser;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Comments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Comments list
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('workouts')
                        .doc(workoutId)
                        .collection('comments')
                        .snapshots(includeMetadataChanges: false),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Error loading comments: ${snapshot.error}',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData) {
                        return const Center(
                          child: Text('No comments yet'),
                        );
                      }

                      final comments = snapshot.data!.docs;
                      
                      if (comments.isEmpty) {
                        return const Center(
                          child: Text('No comments yet'),
                        );
                      }
                      
                      // Sort comments by createdAt client-side
                      final sortedComments = List.from(comments);
                      sortedComments.sort((a, b) {
                        final aTime = a.data()['createdAt'] as Timestamp?;
                        final bTime = b.data()['createdAt'] as Timestamp?;
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        return aTime.compareTo(bTime);
                      });

                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedComments.length,
                        itemBuilder: (context, index) {
                          final comment = sortedComments[index].data();
                          final commentId = sortedComments[index].id;
                          final likes = List<dynamic>.from(
                              comment['likes'] as List? ?? []);
                          final isLikedByOwner =
                              user?.uid == postOwnerId &&
                                  likes.contains(user?.uid);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.grey[300],
                                  child: Text(
                                    ((comment['userName'] as String?) ?? 'A')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['userName'] as String? ??
                                            'Anonymous',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment['text'] as String? ?? '',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (user?.uid == postOwnerId)
                                            GestureDetector(
                                              onTap: () {
                                                _toggleCommentLike(
                                                    workoutId, commentId, likes);
                                              },
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isLikedByOwner
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    size: 16,
                                                    color: isLikedByOwner
                                                        ? Colors.red
                                                        : Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${likes.length}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                // Comment input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: const Color(0xFF1a1d2e),
                        onPressed: () {
                          if (commentController.text.trim().isNotEmpty) {
                            _addComment(workoutId, commentController.text);
                            commentController.clear();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
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
        body: const Center(
          child: Text('Please log in to view the feed.'),
        ),
      );
    }

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
              final doc = docs[index];
              final data = doc.data();
              return _buildFeedCard(doc.id, data, user.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildFeedCard(
      String workoutId, Map<String, dynamic> data, String currentUserId) {
    final userName = (data['userName'] as String?) ?? 'Beast Mode Athlete';
    final goal = data['userGoal'] as String?;
    final title = (data['title'] as String?) ?? 'Workout';
    final notes = (data['notes'] as String?) ?? '';
    final duration = data['durationMinutes'] as int?;
    final postOwnerId = data['userId'] as String? ?? '';
    final likes = List<dynamic>.from(data['likes'] as List? ?? []);
    final likeCount = likes.length;
    final isLiked = likes.contains(currentUserId);

    DateTime date;
    final ts = data['date'];
    if (ts is Timestamp) {
      date = ts.toDate();
    } else {
      date = DateTime.now();
    }

    final dateLabel = '${date.month}/${date.day}/${date.year}';

    String subtitle = '$dateLabel';
    if (duration != null) {
      subtitle += ' • $duration min';
    }
    if (goal != null && goal.isNotEmpty) {
      subtitle += ' • $goal';
    }

    // Get comment count
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('workouts')
          .doc(workoutId)
          .collection('comments')
          .snapshots(),
      builder: (context, commentSnapshot) {
        final commentCount = commentSnapshot.data?.docs.length ?? 0;

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
                // Workout title
            Text(
                  title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
                if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
                    notes,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
            const SizedBox(height: 16),
            // Like and comment buttons
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleLike(workoutId, likes),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isLiked ? Colors.red : Colors.grey[600],
                          ),
                    const SizedBox(width: 4),
                    Text(
                            '$likeCount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                      ),
                ),
                const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => _showCommentsDialog(workoutId, postOwnerId),
                      child: Row(
                  children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                    const SizedBox(width: 4),
                    Text(
                            '$commentCount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ),
        );
      },
    );
  }
}
