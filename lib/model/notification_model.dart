// lib/model/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationStatus {
  pending,
  inProgress,
  completed,
  overdue,
}

class NotificationModel {
  final String id; // Firestore document ID
  final String title; // Task title
  final String description; // Task description
  final NotificationStatus status; // Task status
  final String assignedUserId; // User the task is assigned to
  final String assignedBy; // User who assigned the task
  final DateTime? dueDate; // Task due date
  final DateTime createdAt; // Task creation timestamp
  final bool isRead; // Whether the notification has been read
  final String? taskTemplateId; // Reference to task template (from AssignTasksPage)
  final String? customInstructions; // Custom instructions from assignment

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.assignedUserId,
    required this.assignedBy,
    this.dueDate,
    required this.createdAt,
    required this.isRead,
    this.taskTemplateId,
    this.customInstructions,
  });

  // Convert Firestore document to NotificationModel
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      description: data['description'] ?? '',
      status: _parseStatus(data['status'] ?? 'pending'),
      assignedUserId: data['assignedUserId'] ?? '',
      assignedBy: data['assignedBy'] ?? 'Unknown',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      taskTemplateId: data['taskTemplateId'],
      customInstructions: data['customInstructions'],
    );
  }

  // Convert NotificationModel to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'status': status.toString().split('.').last,
      'assignedUserId': assignedUserId,
      'assignedBy': assignedBy,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'taskTemplateId': taskTemplateId,
      'customInstructions': customInstructions,
    };
  }

  // Parse status string to NotificationStatus enum
  static NotificationStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return NotificationStatus.pending;
      case 'in progress':
        return NotificationStatus.inProgress;
      case 'completed':
        return NotificationStatus.completed;
      case 'overdue':
        return NotificationStatus.overdue;
      default:
        return NotificationStatus.pending;
    }
  }
}