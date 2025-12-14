import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../services/notification_service.dart';
import 'notifications_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  static const int _pageSize = 20;

  Stream<QuerySnapshot<Map<String, dynamic>>> _feedStream() {
    return FirebaseFirestore.instance
        .collection('workouts')
        .orderBy('date', descending: true)
        .limit(_pageSize)
        .snapshots();
  }

  Future<void> _toggleLike(
    String workoutId,
    List<dynamic> currentLikes,
    String postOwnerId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final likes = List<String>.from(currentLikes.map((e) => e.toString()));
    final isLiked = likes.contains(user.uid);

    if (isLiked) {
      likes.remove(user.uid);
    } else {
      likes.add(user.uid);

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userName =
            userDoc.data()?['displayName'] as String? ??
            user.email ??
            'Someone';

        await NotificationService.createLikeNotification(
          postId: workoutId,
          postOwnerId: postOwnerId,
          likerId: user.uid,
          likerName: userName,
        );
      } catch (e) {
        print('Error creating like notification: $e');
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('workouts')
          .doc(workoutId)
          .update({'likes': likes});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _addComment(
    String workoutId,
    String commentText,
    String postOwnerId, {
    String? parentCommentId,
    String? parentCommentOwnerId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || commentText.trim().isEmpty) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName =
          userDoc.data()?['displayName'] as String? ??
          user.email ??
          'Anonymous';

      if (parentCommentId != null) {
        await FirebaseFirestore.instance
            .collection('workouts')
            .doc(workoutId)
            .collection('comments')
            .doc(parentCommentId)
            .collection('replies')
            .add({
              'userId': user.uid,
              'userName': userName,
              'text': commentText.trim(),
              'createdAt': Timestamp.now(),
            });

        if (parentCommentOwnerId != null) {
          await NotificationService.createReplyNotification(
            postId: workoutId,
            commentId: parentCommentId,
            commentOwnerId: parentCommentOwnerId,
            replierId: user.uid,
            replierName: userName,
            replyText: commentText.trim(),
          );
        }
      } else {
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

        // Update comment count in workout document (optimization)
        final workoutRef = FirebaseFirestore.instance
            .collection('workouts')
            .doc(workoutId);
        final workoutDoc = await workoutRef.get();
        final currentCount = workoutDoc.data()?['commentCount'] as int? ?? 0;
        await workoutRef.update({'commentCount': currentCount + 1});

        await NotificationService.createCommentNotification(
          postId: workoutId,
          postOwnerId: postOwnerId,
          commenterId: user.uid,
          commenterName: userName,
          commentText: commentText.trim(),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding comment: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _toggleCommentLike(
    String workoutId,
    String commentId,
    List<dynamic> currentLikes,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final workoutDoc = await FirebaseFirestore.instance
        .collection('workouts')
        .doc(workoutId)
        .get();
    final workoutUserId = workoutDoc.data()?['userId'] as String?;

    if (workoutUserId != user.uid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only the post owner can like comments.'),
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Widget _buildCommentWidget({
    required String workoutId,
    required String commentId,
    required Map<String, dynamic> comment,
    required String commentOwnerId,
    required String postOwnerId,
    required bool isLikedByOwner,
    required List<dynamic> likes,
    required VoidCallback onReply,
    User? user,
  }) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = comment['userName'] as String? ?? 'Anonymous';
    final commentText = comment['text'] as String? ?? '';

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('workouts')
          .doc(workoutId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, repliesSnapshot) {
        final replies = repliesSnapshot.data?.docs ?? [];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[300],
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(commentText, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (user?.uid == postOwnerId)
                              GestureDetector(
                                onTap: () {
                                  _toggleCommentLike(
                                    workoutId,
                                    commentId,
                                    likes,
                                  );
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
                            if (user?.uid == postOwnerId && replies.isNotEmpty)
                              const SizedBox(width: 12),
                            TextButton(
                              onPressed: onReply,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Reply',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (replies.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 44),
                  child: Column(
                    children: replies.map((replyDoc) {
                      final reply = replyDoc.data();
                      final replyUserName =
                          reply['userName'] as String? ?? 'Anonymous';
                      final replyText = reply['text'] as String? ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                replyUserName.isNotEmpty
                                    ? replyUserName[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    replyUserName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    replyText,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showCommentsDialog(String workoutId, String postOwnerId) {
    final user = FirebaseAuth.instance.currentUser;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _CommentsDialogContent(
          workoutId: workoutId,
          postOwnerId: postOwnerId,
          user: user,
          onAddComment: _addComment,
          buildCommentWidget: _buildCommentWidget,
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
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'BEAST MODE FEED',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          centerTitle: false,
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: Text('Please log in to view the feed.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'BEAST MODE FEED',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('userId', isEqualTo: user.uid)
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
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

          final allDocs = snapshot.data?.docs ?? [];

          final docs = allDocs.where((doc) {
            final data = doc.data();
            final isPrivate = data['userIsPrivate'] as bool?;
            return isPrivate != true;
          }).toList();

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
    String workoutId,
    Map<String, dynamic> data,
    String currentUserId,
  ) {
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

    String subtitle = dateLabel;
    if (duration != null) {
      subtitle += ' • $duration min';
    }
    if (goal != null && goal.isNotEmpty) {
      subtitle += ' • $goal';
    }

    // Use cached comment count from data if available, otherwise show placeholder
    // This avoids expensive per-item queries
    final commentCount = data['commentCount'] as int?;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WorkoutDetailScreen(
              workoutId: workoutId,
              postOwnerId: postOwnerId,
            ),
          ),
        );
      },
      child: Card(
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
              Row(
                children: [
                  if (postOwnerId.isEmpty)
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
                    )
                  else
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(postOwnerId)
                          .get(),
                      builder: (context, snapshot) {
                        String? photoUrl;
                        if (snapshot.hasData && snapshot.data!.data() != null) {
                          photoUrl =
                              snapshot.data!.data()!['photoUrl'] as String?;
                        }

                        if (photoUrl != null && photoUrl.isNotEmpty) {
                          return CircleAvatar(
                            radius: 20,
                            backgroundImage: CachedNetworkImageProvider(
                              photoUrl,
                            ),
                          );
                        }

                        return CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'B',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
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
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _toggleLike(workoutId, likes, postOwnerId),
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
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 20,
                          color: Color.fromARGB(159, 0, 0, 0),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          commentCount != null ? '$commentCount' : '0',
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.touch_app,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Press to view full workout',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentsDialogContent extends StatefulWidget {
  final String workoutId;
  final String postOwnerId;
  final User? user;
  final Future<void> Function(
    String,
    String,
    String, {
    String? parentCommentId,
    String? parentCommentOwnerId,
  })
  onAddComment;
  final Widget Function({
    required String workoutId,
    required String commentId,
    required Map<String, dynamic> comment,
    required String commentOwnerId,
    required String postOwnerId,
    required bool isLikedByOwner,
    required List<dynamic> likes,
    required VoidCallback onReply,
    User? user,
  })
  buildCommentWidget;

  const _CommentsDialogContent({
    required this.workoutId,
    required this.postOwnerId,
    required this.user,
    required this.onAddComment,
    required this.buildCommentWidget,
  });

  @override
  State<_CommentsDialogContent> createState() => _CommentsDialogContentState();
}

class _CommentsDialogContentState extends State<_CommentsDialogContent> {
  late final TextEditingController _commentController;
  late final ValueNotifier<String?> _replyingToCommentId;
  late final ValueNotifier<String?> _replyingToUserName;
  late final ValueNotifier<String?> _replyingToCommentOwnerId;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _replyingToCommentId = ValueNotifier<String?>(null);
    _replyingToUserName = ValueNotifier<String?>(null);
    _replyingToCommentOwnerId = ValueNotifier<String?>(null);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyingToCommentId.dispose();
    _replyingToUserName.dispose();
    _replyingToCommentOwnerId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return ValueListenableBuilder<String?>(
            valueListenable: _replyingToCommentId,
            builder: (context, currentReplyId, _) {
              return Column(
                children: [
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
                  Expanded(
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('workouts')
                          .doc(widget.workoutId)
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
                          return const Center(child: Text('No comments yet'));
                        }

                        final comments = snapshot.data!.docs;

                        if (comments.isEmpty) {
                          return const Center(child: Text('No comments yet'));
                        }

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
                            final commentOwnerId =
                                comment['userId'] as String? ?? '';
                            final likes = List<dynamic>.from(
                              comment['likes'] as List? ?? [],
                            );
                            final isLikedByOwner =
                                widget.user?.uid == widget.postOwnerId &&
                                likes.contains(widget.user?.uid);

                            return widget.buildCommentWidget(
                              workoutId: widget.workoutId,
                              commentId: commentId,
                              comment: comment,
                              commentOwnerId: commentOwnerId,
                              postOwnerId: widget.postOwnerId,
                              isLikedByOwner: isLikedByOwner,
                              likes: likes,
                              onReply: () {
                                _replyingToCommentId.value = commentId;
                                _replyingToUserName.value =
                                    comment['userName'] as String? ??
                                    'Anonymous';
                                _replyingToCommentOwnerId.value =
                                    commentOwnerId;
                                _commentController.clear();
                              },
                              user: widget.user,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (currentReplyId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.blue[50],
                      child: Row(
                        children: [
                          Icon(Icons.reply, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Replying to ${_replyingToUserName.value ?? 'comment'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              _replyingToCommentId.value = null;
                              _replyingToUserName.value = null;
                              _replyingToCommentOwnerId.value = null;
                              _commentController.clear();
                            },
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: currentReplyId != null
                                  ? 'Write a reply...'
                                  : 'Write a comment...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (value) {
                              if (value.trim().isNotEmpty) {
                                widget.onAddComment(
                                  widget.workoutId,
                                  value,
                                  widget.postOwnerId,
                                  parentCommentId: _replyingToCommentId.value,
                                  parentCommentOwnerId:
                                      _replyingToCommentOwnerId.value,
                                );
                                _commentController.clear();
                                _replyingToCommentId.value = null;
                                _replyingToUserName.value = null;
                                _replyingToCommentOwnerId.value = null;
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: const Color(0xFF1a1d2e),
                          onPressed: () {
                            if (_commentController.text.trim().isNotEmpty) {
                              widget.onAddComment(
                                widget.workoutId,
                                _commentController.text,
                                widget.postOwnerId,
                                parentCommentId: _replyingToCommentId.value,
                                parentCommentOwnerId:
                                    _replyingToCommentOwnerId.value,
                              );
                              _commentController.clear();
                              _replyingToCommentId.value = null;
                              _replyingToUserName.value = null;
                              _replyingToCommentOwnerId.value = null;
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
      ),
    );
  }
}

class WorkoutDetailScreen extends StatelessWidget {
  final String workoutId;
  final String postOwnerId;

  const WorkoutDetailScreen({
    super.key,
    required this.workoutId,
    required this.postOwnerId,
  });

  static const _cardBg = Color.fromARGB(52, 174, 174, 174);

  String _fmtDate(dynamic ts) {
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.month}/${d.day}/${d.year}';
    }
    return '';
  }

  String _prettyValue(dynamic v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is num || v is bool) return v.toString();
    if (v is Timestamp) return _fmtDate(v);
    return v.toString();
  }

  String _labelize(String k) {
    final s = k.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoRow(String k, String v) {
    if (v.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              k,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _styledCard({required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: _cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _exerciseCard(Map<String, dynamic> ex) {
    final name = (ex['name'] as String?) ?? 'Exercise';

    final ignoreKeys = <String>{
      'name',
      'createdAt',
      'updatedAt',
      'id',
      'workoutId',
    };

    final entries = ex.entries
        .where((e) => !ignoreKeys.contains(e.key) && e.value != null)
        .toList();

    return _styledCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...entries.map((e) {
              final v = _prettyValue(e.value);
              if (v.trim().isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(
                        _labelize(e.key),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        v,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutRef = FirebaseFirestore.instance
        .collection('workouts')
        .doc(workoutId);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: workoutRef.snapshots(),
        builder: (context, workoutSnap) {
          if (workoutSnap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (!workoutSnap.hasData || workoutSnap.data?.data() == null) {
            return const Center(child: Text('Workout not found.'));
          }

          final w = workoutSnap.data!.data()!;

          final userName = (w['userName'] as String?) ?? 'Beast Mode Athlete';
          final title = (w['title'] as String?) ?? 'Workout';
          final notes = (w['notes'] as String?) ?? '';
          final goal = (w['userGoal'] as String?) ?? '';
          final duration = w['durationMinutes'];
          final dateLabel = _fmtDate(w['date']);

          String subtitle = dateLabel;
          if (duration != null) subtitle += ' • ${duration.toString()} min';
          if (goal.trim().isNotEmpty) subtitle += ' • $goal';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _styledCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: postOwnerId.isEmpty
                              ? null
                              : FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(postOwnerId)
                                    .get(),
                          builder: (context, snap) {
                            String? photoUrl;
                            if (snap.hasData && snap.data?.data() != null) {
                              photoUrl =
                                  snap.data!.data()!['photoUrl'] as String?;
                            }

                            if (photoUrl != null && photoUrl.isNotEmpty) {
                              return CircleAvatar(
                                radius: 20,
                                backgroundImage: CachedNetworkImageProvider(
                                  photoUrl,
                                ),
                              );
                            }

                            return CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.grey[300],
                              child: Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : 'B',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notes,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ],
                  ],
                ),
              ),

              _sectionTitle('Workout Info'),
              _styledCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Date', dateLabel),
                    _infoRow(
                      'Duration',
                      duration == null ? '' : '${duration.toString()} min',
                    ),
                    _infoRow('Goal', goal),
                    if (notes.trim().isNotEmpty) _infoRow('Notes', notes),
                  ],
                ),
              ),

              _sectionTitle('Exercises'),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: workoutRef
                    .collection('exercises')
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, exSnap) {
                  if (exSnap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final exDocs = exSnap.data?.docs ?? [];
                  final fallbackArray = (w['exercises'] is List)
                      ? (w['exercises'] as List)
                      : const [];

                  if (exDocs.isEmpty && fallbackArray.isEmpty) {
                    return _styledCard(
                      child: const Text('No exercises saved for this workout.'),
                    );
                  }

                  if (exDocs.isEmpty && fallbackArray.isNotEmpty) {
                    return Column(
                      children: fallbackArray.map((e) {
                        final m = (e is Map)
                            ? Map<String, dynamic>.from(e as Map)
                            : <String, dynamic>{'name': 'Exercise', 'value': e};
                        return _exerciseCard(m);
                      }).toList(),
                    );
                  }

                  return Column(
                    children: exDocs
                        .map((d) => _exerciseCard(d.data()))
                        .toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
