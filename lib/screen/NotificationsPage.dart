import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _showUnreadOnly = true;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: const Color(0xFF1F2937),
        ),
        body: const Center(
          child: Text('Please log in to view notifications'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF1F2937),
        actions: [
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.all_inclusive : Icons.mark_unread_chat_alt,
              color: _showUnreadOnly ? const Color(0xFF2563EB) : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
              });
            },
            tooltip: _showUnreadOnly ? 'Show All' : 'Show Unread Only',
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('assignedUserId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(color: Colors.red[600], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showUnreadOnly ? 'No unread notifications' : 'No tasks assigned',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          // Client-side sorting by createdAt (descending)
          final tasks = snapshot.data!.docs;
          tasks.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aCreatedAt = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            final bCreatedAt = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
            return bCreatedAt.compareTo(aCreatedAt); // Descending
          });

          final filteredTasks = _showUnreadOnly
              ? tasks.where((task) => (task.data() as Map<String, dynamic>)['isRead'] != true).toList()
              : tasks;

          if (filteredTasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${_showUnreadOnly ? 'unread' : 'notifications'} found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Showing ${filteredTasks.length} ${_showUnreadOnly ? 'unread' : 'notifications'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    final taskData = task.data() as Map<String, dynamic>;
                    final isRead = taskData['isRead'] ?? false;
                    return _buildNotificationCard(task, taskData, isRead);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(
    DocumentSnapshot task,
    Map<String, dynamic> taskData,
    bool isRead,
  ) {
    final taskTitle = taskData['title'] ?? 'Untitled Task';
    final taskDescription = taskData['description'] ?? '';
    final taskStatus = taskData['status'] ?? 'unknown';
    final createdAt = (taskData['createdAt'] as Timestamp?)?.toDate();
    final dueDate = (taskData['dueDate'] as Timestamp?)?.toDate();
    final assignedBy = taskData['assignedBy'] ?? 'System';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isRead ? 1 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isRead ? Colors.transparent : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _markAsRead(task.id, !isRead);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(taskStatus).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(taskStatus),
                  color: _getStatusColor(taskStatus),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            taskTitle,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRead ? Colors.grey : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    if (taskDescription.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        taskDescription,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assigned by $assignedBy',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        if (createdAt != null)
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                        if (createdAt != null) const SizedBox(width: 4),
                        if (createdAt != null)
                          Text(
                            DateFormat('MMM dd, HH:mm').format(createdAt),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: _getDueDateColor(dueDate),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Due: ${DateFormat.yMMMd().format(dueDate)}',
                            style: TextStyle(
                              color: _getDueDateColor(dueDate),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isRead ? Icons.mark_chat_read : Icons.markunread,
                  color: isRead ? Colors.grey : const Color(0xFF2563EB),
                ),
                onPressed: () => _markAsRead(task.id, !isRead),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(String taskId, bool isRead) async {
    try {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'isRead': isRead});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update notification: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final tasks = await FirebaseFirestore.instance
          .collection('tasks')
          .where('assignedUserId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var task in tasks.docs) {
        batch.update(task.reference, {'isRead': true});
      }

      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to mark all as read: $e')),
      );
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_outlined;
      case 'in progress':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check_circle;
      case 'overdue':
        return Icons.warning_amber;
      default:
        return Icons.info_outline;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF856404);
      case 'in progress':
        return const Color(0xFF2563EB);
      case 'completed':
        return const Color(0xFF155724);
      case 'overdue':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    if (difference < 0) return const Color(0xFFDC2626); // Overdue
    if (difference <= 1) return const Color(0xFFFF6B35); // Due soon
    return const Color(0xFF16A34A); // On time
  }
}