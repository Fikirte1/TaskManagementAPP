import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_management/model/assignment_models.dart';

class DataInitializer {
  static Future<void> initializeSampleData() async {
    final teamMembersCollection = FirebaseFirestore.instance.collection('teamMembers');
    final tasksCollection = FirebaseFirestore.instance.collection('tasks');
    final assignmentsCollection = FirebaseFirestore.instance.collection('assignments');
    final issuesCollection = FirebaseFirestore.instance.collection('issues');
    final projectsCollection = FirebaseFirestore.instance.collection('projects');
    final progressDataCollection = FirebaseFirestore.instance.collection('progressData');

    // Clear existing data
    final collections = [
      teamMembersCollection,
      tasksCollection,
      assignmentsCollection,
      issuesCollection,
      projectsCollection,
      progressDataCollection
    ];
    for (var collection in collections) {
      final docs = await collection.get();
      for (var doc in docs.docs) {
        await doc.reference.delete();
      }
    }

    // Add team members
    final teamMembers = [
      TeamMember(
        id: 'member1',
        name: 'Alice Johnson',
        role: 'Developer',
        email: 'alice@example.com',
        joinedDate: DateTime(2023, 1, 15),
        avatar: 'AJ',
        assignedTasks: 3,
        completedTasks: 2,
        productivity: 0.67,
      ),
      TeamMember(
        id: 'member2',
        name: 'Bob Smith',
        role: 'Designer',
        email: 'bob@example.com',
        joinedDate: DateTime(2023, 2, 20),
        avatar: 'BS',
        assignedTasks: 2,
        completedTasks: 1,
        productivity: 0.5,
      ),
    ];

    for (var member in teamMembers) {
      await teamMembersCollection.add(member.toMap());
    }

    // Add projects
    final projects = [
      Project(
        id: 'project1',
        name: 'Mobile App Development',
        description: 'Develop a cross-platform mobile application',
        startDate: DateTime(2025, 9, 24),
        endDate: DateTime(2025, 12, 31),
        teamMembers: ['member1', 'member2'],
        createdAt: DateTime.now(),
        progress: 0.35,
        totalTasks: 2,
        completedTasks: 1,
        color: Color(0xFF10B981),
        manager: 'Alice Johnson',
      ),
      Project(
        id: 'project2',
        name: 'Website Redesign',
        description: 'Redesign company website for better UX',
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2026, 3, 31),
        teamMembers: ['member2'],
        createdAt: DateTime.now(),
        progress: 0.5,
        totalTasks: 1,
        completedTasks: 0,
        color: Color(0xFF6366F1),
        manager: 'Bob Smith',
      ),
    ];

    for (var project in projects) {
      await projectsCollection.add(project.toMap());
    }

    // Add tasks
    final tasks = [
      Task(
        id: 'task1',
        title: 'UI/UX Design',
        description: 'Design the user interface for the mobile app',
        project: 'project1',
        assignedTo: 'member1',
        dueDate: DateTime.now().add(Duration(days: 7)),
        priority: TaskPriority.high,
        status: TaskStatus.todo,
        createdAt: DateTime.now(),
      ),
      Task(
        id: 'task2',
        title: 'API Integration',
        description: 'Integrate REST API with the backend',
        project: 'project1',
        assignedTo: 'member2',
        dueDate: DateTime.now().add(Duration(days: 5)),
        priority: TaskPriority.medium,
        status: TaskStatus.completed,
        createdAt: DateTime.now(),
      ),
      Task(
        id: 'task3',
        title: 'Homepage Redesign',
        description: 'Redesign homepage layout',
        project: 'project2',
        assignedTo: 'member2',
        dueDate: DateTime.now().add(Duration(days: 10)),
        priority: TaskPriority.medium,
        status: TaskStatus.inProgress,
        createdAt: DateTime.now(),
      ),
    ];

    for (var task in tasks) {
      await tasksCollection.add(task.toMap());
    }

    // Add task templates
    final taskTemplates = tasks.map((task) => TaskTemplate.fromTask(task)).toList();
    for (var template in taskTemplates) {
      await tasksCollection.add(template.toMap());
    }

    // Add assignments
    final assignments = [
      Assignment(
        id: 'assignment1',
        taskTemplateId: 'task1',
        assignedToId: 'member1',
        title: 'UI/UX Design',
        description: 'Design the user interface for the mobile app',
        dueDate: DateTime.now().add(Duration(days: 7)),
        assignedAt: DateTime.now(),
        customInstructions: 'Follow the design guidelines provided',
        status: AssignmentStatus.assigned,
      ),
      Assignment(
        id: 'assignment2',
        taskTemplateId: 'task2',
        assignedToId: 'member2',
        title: 'API Integration',
        description: 'Integrate REST API with the backend',
        dueDate: DateTime.now().add(Duration(days: 5)),
        assignedAt: DateTime.now(),
        customInstructions: 'Ensure compatibility with v2 API',
        status: AssignmentStatus.completed,
      ),
    ];

    for (var assignment in assignments) {
      await assignmentsCollection.add(assignment.toMap());
    }

    // Add issues
    final issues = [
      Issue(
        id: 'issue1',
        title: 'Bug in Login Form',
        description: 'Login form crashes on invalid input',
        priority: IssuePriority.high,
        status: IssueStatus.open,
        assignedTo: 'member1',
        createdAt: DateTime.now(),
        dueDate: DateTime.now().add(Duration(days: 3)),
        projectId: 'project1',
      ),
      Issue(
        id: 'issue2',
        title: 'UI Alignment Issue',
        description: 'Buttons misaligned on smaller screens',
        priority: IssuePriority.medium,
        status: IssueStatus.inProgress,
        assignedTo: 'member2',
        createdAt: DateTime.now().subtract(Duration(days: 2)),
        dueDate: DateTime.now().add(Duration(days: 5)),
        projectId: 'project1',
      ),
    ];

    for (var issue in issues) {
      await issuesCollection.add(issue.toMap());
    }

    // Add progress data
    final progressData = [
      ProgressData(
        id: 'progress1',
        day: '2025-09-18',
        progress: 0.2,
        tasksCompleted: 1,
        projectId: 'project1',
        createdAt: DateTime.now().subtract(Duration(days: 6)),
      ),
      ProgressData(
        id: 'progress2',
        day: '2025-09-19',
        progress: 0.3,
        tasksCompleted: 2,
        projectId: 'project1',
        createdAt: DateTime.now().subtract(Duration(days: 5)),
      ),
      ProgressData(
        id: 'progress3',
        day: '2025-09-20',
        progress: 0.35,
        tasksCompleted: 3,
        projectId: 'project1',
        createdAt: DateTime.now().subtract(Duration(days: 4)),
      ),
      ProgressData(
        id: 'progress4',
        day: '2025-09-18',
        progress: 0.1,
        tasksCompleted: 0,
        projectId: 'project2',
        createdAt: DateTime.now().subtract(Duration(days: 6)),
      ),
    ];

    for (var progress in progressData) {
      await progressDataCollection.add(progress.toMap());
    }
  }
}