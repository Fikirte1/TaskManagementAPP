import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/notification_model.dart';

class NotificationService {
  final CollectionReference _notificationsRef =
      FirebaseFirestore.instance.collection('notifications');

  /// Create new notification
  Future<void> createNotification(NotificationModel notif) async {
    await _notificationsRef.add(notif.toMap());
  }

  /// Stream notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _notificationsRef
        .where('assignedToId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  /// Mark notification as read
  Future<void> markAsRead(String notifId) async {
    await _notificationsRef.doc(notifId).update({"status": "read"});
  }

  /// Delete notification
  Future<void> deleteNotification(String notifId) async {
    await _notificationsRef.doc(notifId).delete();
  }

  static getUnreadNotificationCount(String uid) {}
}
