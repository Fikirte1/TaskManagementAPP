import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/model/assignment_models.dart';
import 'package:task_management/service/assignment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<TaskNotification> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  void _loadNotifications() {
  final user = FirebaseAuth.instance.currentUser;
  print('User: ${user?.uid}');
  if (user == null) {
    setState(() {
      _isLoading = false;
      _errorMessage = 'Please log in to view notifications';
    });
    return;
  }

  _notificationsSubscription = AssignmentService.getNotifications(user.uid).listen(
    (QuerySnapshot snapshot) {
      if (!mounted) return;
      final notifications = snapshot.docs.map((doc) {
        try {
          return TaskNotification.fromFirestore(doc);
        } catch (e) {
          print('Error parsing notification ${doc.id}: $e');
          return null;
        }
      }).whereType<TaskNotification>().toList();
      print('Loaded ${notifications.length} notifications');
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    },
    onError: (error) {
      print('Error loading notifications: $error');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notifications: $error';
          _isLoading = false;
        });
      }
    },
  );
}

  Future<void> _markAsRead(String notificationId) async {
    try {
      await AssignmentService.markNotificationAsRead(notificationId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification marked as read'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark as read: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _notifications.isEmpty
                  ? const Center(child: Text('No notifications available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildNotificationCard(notification);
                      },
                    ),
    );
  }

  Widget _buildNotificationCard(TaskNotification notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: notification.isRead ? Colors.white : const Color(0xFFE0F2FE),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(
          Icons.notifications,
          color: notification.isRead ? Colors.grey : const Color(0xFF2563EB),
          size: 30,
        ),
        title: Text(
          notification.taskName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: notification.isRead ? Colors.grey[600] : const Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('MMM dd, yyyy - hh:mm a').format(notification.createdAt),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? IconButton(
                icon: const Icon(Icons.check_circle, color: Color(0xFF10B981)),
                onPressed: () => _markAsRead(notification.id),
              )
            : null,
      ),
    );
  }
}