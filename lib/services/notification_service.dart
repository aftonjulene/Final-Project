import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a notification when someone likes a post
  static Future<void> createLikeNotification({
    required String postId,
    required String postOwnerId,
    required String likerId,
    required String likerName,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Don't notify if user likes their own post
    if (postOwnerId == likerId) return;

    try {
      // Check if notification already exists (prevent duplicates)
      final existingNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: postOwnerId)
          .where('type', isEqualTo: 'like')
          .where('postId', isEqualTo: postId)
          .where('fromUserId', isEqualTo: likerId)
          .where('read', isEqualTo: false)
          .get();

      if (existingNotifications.docs.isNotEmpty) {
        // Update existing notification timestamp
        await existingNotifications.docs.first.reference.update({
          'createdAt': FieldValue.serverTimestamp(),
        });
        return;
      }

      await _firestore.collection('notifications').add({
        'userId': postOwnerId,
        'type': 'like',
        'postId': postId,
        'fromUserId': likerId,
        'fromUserName': likerName,
        'message': '$likerName liked your post',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating like notification: $e');
    }
  }

  /// Create a notification when someone comments on a post
  static Future<void> createCommentNotification({
    required String postId,
    required String postOwnerId,
    required String commenterId,
    required String commenterName,
    required String commentText,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Don't notify if user comments on their own post
    if (postOwnerId == commenterId) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': postOwnerId,
        'type': 'comment',
        'postId': postId,
        'fromUserId': commenterId,
        'fromUserName': commenterName,
        'message': '$commenterName commented on your post',
        'commentText': commentText.length > 50
            ? '${commentText.substring(0, 50)}...'
            : commentText,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating comment notification: $e');
    }
  }

  /// Create a notification when someone replies to a comment
  static Future<void> createReplyNotification({
    required String postId,
    required String commentId,
    required String commentOwnerId,
    required String replierId,
    required String replierName,
    required String replyText,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // Don't notify if user replies to their own comment
    if (commentOwnerId == replierId) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': commentOwnerId,
        'type': 'reply',
        'postId': postId,
        'commentId': commentId,
        'fromUserId': replierId,
        'fromUserName': replierName,
        'message': '$replierName replied to your comment',
        'replyText': replyText.length > 50
            ? '${replyText.substring(0, 50)}...'
            : replyText,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error creating reply notification: $e');
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read for a user
  static Future<void> markAllAsRead(String userId) async {
    try {
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Get unread notification count
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}

