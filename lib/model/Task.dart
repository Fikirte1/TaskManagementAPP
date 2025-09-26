import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskPriority { low, medium, high, urgent }
enum TaskStatus { todo, inProgress, review, completed }

class Task {
  final String id;
  final String title;
  final String description;
  final String project;
  final String assignedTo;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.project,
    required this.assignedTo,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'project': project,
      'assignedTo': assignedTo,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': _priorityToString(priority),
      'status': _statusToString(status),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      project: data['project'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: _stringToPriority(data['priority'] ?? 'medium'),
      status: _stringToStatus(data['status'] ?? 'todo'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  static String _priorityToString(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.urgent:
        return 'urgent';
    }
  }

  static TaskPriority _stringToPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  static String _statusToString(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'inProgress';
      case TaskStatus.review:
        return 'review';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus _stringToStatus(String status) {
    switch (status.toLowerCase()) {
      case 'todo':
        return TaskStatus.todo;
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'review':
        return TaskStatus.review;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.todo;
    }
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? project,
    String? assignedTo,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      project: project ?? this.project,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}