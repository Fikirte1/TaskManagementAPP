import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high, urgent }
enum TaskStatus { todo, inProgress, review, completed }
enum AssignmentStatus { assigned, inProgress, completed }
enum IssuePriority { low, medium, high }
enum IssueStatus { open, inProgress, resolved }

class Project {
  final String id;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final List<String> teamMembers;
  final DateTime createdAt;
  final double progress;
  final int totalTasks;
  final int completedTasks;
  final Color color;
  final String manager;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.teamMembers,
    required this.createdAt,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
    required this.color,
    required this.manager,
  });

  factory Project.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Project(
      id: doc.id,
      name: data['name'] ?? 'Untitled Project',
      description: data['description'] ?? 'No description',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      teamMembers: List<String>.from(data['teamMembers'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      totalTasks: data['totalTasks'] ?? 0,
      completedTasks: data['completedTasks'] ?? 0,
      color: _parseColor(data['color']),
      manager: data['manager'] ?? 'Unassigned',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'teamMembers': teamMembers,
      'createdAt': Timestamp.fromDate(createdAt),
      'progress': progress,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}',
      'manager': manager,
    };
  }

  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.blue;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }
}

class TeamMember {
  final String id;
  final String name;
  final String role;
  final String email;
  final DateTime joinedDate;
  final String avatar;
  final int assignedTasks;
  final int completedTasks;
  final double productivity;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.joinedDate,
    required this.avatar,
    required this.assignedTasks,
    required this.completedTasks,
    required this.productivity,
  });

  factory TeamMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeamMember(
      id: doc.id,
      name: data['name'] ?? 'Unknown Member',
      role: data['role'] ?? 'No Role',
      email: data['email'] ?? '',
      joinedDate: (data['joinedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      avatar: data['avatar'] ?? 'NA',
      assignedTasks: data['assignedTasks'] ?? 0,
      completedTasks: data['completedTasks'] ?? 0,
      productivity: (data['productivity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'joinedDate': Timestamp.fromDate(joinedDate),
      'avatar': avatar,
      'assignedTasks': assignedTasks,
      'completedTasks': completedTasks,
      'productivity': productivity,
    };
  }
}

class TaskTemplate {
  final String id;
  final String title;
  final String description;
  final String category;
  final int estimatedHours;
  final List<String> requiredSkills;

  TaskTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedHours,
    required this.requiredSkills,
  });

  factory TaskTemplate.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskTemplate(
      id: doc.id,
      title: data['title'] ?? 'Untitled Task',
      description: data['description'] ?? 'No description',
      category: data['category'] ?? 'General',
      estimatedHours: data['estimatedHours'] ?? 0,
      requiredSkills: List<String>.from(data['requiredSkills'] ?? []),
    );
  }

  factory TaskTemplate.fromTask(Task task) {
    return TaskTemplate(
      id: task.id,
      title: task.title,
      description: task.description,
      category: task.project,
      estimatedHours: 0,
      requiredSkills: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'estimatedHours': estimatedHours,
      'requiredSkills': requiredSkills,
    };
  }
}

class Assignment {
  final String id;
  final String taskTemplateId;
  final String assignedToId;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime assignedAt;
  final String customInstructions;
  final AssignmentStatus status;

  Assignment({
    required this.id,
    required this.taskTemplateId,
    required this.assignedToId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.assignedAt,
    this.customInstructions = '',
    this.status = AssignmentStatus.assigned,
  });

  factory Assignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Assignment(
      id: doc.id,
      taskTemplateId: data['taskTemplateId'] ?? '',
      assignedToId: data['assignedToId'] ?? '',
      title: data['title'] ?? 'Untitled Assignment',
      description: data['description'] ?? 'No description',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      assignedAt: (data['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      customInstructions: data['customInstructions'] ?? '',
      status: AssignmentStatus.values.firstWhere(
        (status) => status.toString().split('.').last == (data['status'] ?? 'assigned'),
        orElse: () => AssignmentStatus.assigned,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskTemplateId': taskTemplateId,
      'assignedToId': assignedToId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'assignedAt': Timestamp.fromDate(assignedAt),
      'customInstructions': customInstructions,
      'status': status.toString().split('.').last,
    };
  }
}

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
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      project: data['project'] ?? '',
      assignedTo: data['assignedTo'] ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      priority: TaskPriority.values.firstWhere(
        (p) => p.toString().split('.').last == (data['priority'] ?? 'low'),
        orElse: () => TaskPriority.low,
      ),
      status: TaskStatus.values.firstWhere(
        (s) => s.toString().split('.').last == (data['status'] ?? 'todo'),
        orElse: () => TaskStatus.todo,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'project': project,
      'assignedTo': assignedTo,
      'dueDate': Timestamp.fromDate(dueDate),
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Issue {
  final String id;
  final String title;
  final String description;
  final IssuePriority priority;
  final IssueStatus status;
  final String assignedTo;
  final DateTime createdAt;
  final DateTime? dueDate;
  final String? projectId;

  Issue({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.assignedTo,
    required this.createdAt,
    this.dueDate,
    this.projectId,
  });

  factory Issue.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Issue(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priority: IssuePriority.values.firstWhere(
        (e) => e.toString().split('.').last == (data['priority'] ?? 'low'),
        orElse: () => IssuePriority.low,
      ),
      status: IssueStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'open'),
        orElse: () => IssueStatus.open,
      ),
      assignedTo: data['assignedTo'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      projectId: data['projectId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'projectId': projectId,
    };
  }
}

class ProgressData {
  final String id;
  final String day;
  final double progress;
  final int tasksCompleted;
  final String? projectId;
  final DateTime createdAt;

  ProgressData({
    required this.id,
    required this.day,
    required this.progress,
    required this.tasksCompleted,
    this.projectId,
    required this.createdAt,
  });

  factory ProgressData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgressData(
      id: doc.id,
      day: data['day'] ?? '',
      progress: (data['progress'] as num?)?.toDouble() ?? 0.0,
      tasksCompleted: data['tasksCompleted'] ?? 0,
      projectId: data['projectId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'day': day,
      'progress': progress,
      'tasksCompleted': tasksCompleted,
      'projectId': projectId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
}class TaskNotification {
  final String id;
  final String userId;
  final String taskName;
  final String projectId;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  TaskNotification({
    required this.id,
    required this.userId,
    required this.taskName,
    required this.projectId,
    required this.message,
    required this.createdAt,
    required this.isRead,
  });

  factory TaskNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TaskNotification(
      id: doc.id,
      userId: data['userId'] ?? '',
      taskName: data['taskName'] ?? '',
      projectId: data['projectId'] ?? '',
      message: data['message'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'taskName': taskName,
      'projectId': projectId,
      'message': message,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}


  

