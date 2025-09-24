import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_management/model/assignment_models.dart';

class AssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _assignmentsCollection =
      _firestore.collection('assignments');
  static final CollectionReference _teamMembersCollection =
      _firestore.collection('teamMembers');
  static final CollectionReference _taskTemplatesCollection =
      _firestore.collection('tasks');
  static final CollectionReference _issuesCollection =
      _firestore.collection('issues');
  static final CollectionReference _projectsCollection =
      _firestore.collection('projects');
  static final CollectionReference _progressDataCollection =
      _firestore.collection('progressData');

  static Future<String> addAssignment(Map<String, dynamic> assignmentData) async {
    try {
      DocumentReference docRef = await _assignmentsCollection.add(assignmentData);
      await _updateTeamMemberStats(assignmentData['assignedToId']);
      // TODO: Implement FCM notification
      debugPrint('Notification: Assignment assigned to ${assignmentData['assignedToId']}');
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding assignment: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getAssignments() {
    return _assignmentsCollection.orderBy('assignedAt', descending: true).snapshots();
  }

  static Stream<QuerySnapshot> getAssignmentsByMember(String memberId) {
    return _assignmentsCollection
        .where('assignedToId', isEqualTo: memberId)
        .orderBy('dueDate', descending: false)
        .snapshots();
  }

  static Stream<QuerySnapshot> getTeamMembers() {
    return _teamMembersCollection.orderBy('name').snapshots();
  }

  static Stream<QuerySnapshot> getTaskTemplates() {
    return _taskTemplatesCollection
        .where('status', isEqualTo: 'todo')
        .orderBy('title')
        .snapshots();
  }

  static Future<void> addTeamMember(Map<String, dynamic> memberData) async {
    try {
      await _teamMembersCollection.add(memberData);
    } catch (e) {
      debugPrint('Error adding team member: $e');
      rethrow;
    }
  }

  static Future<void> addTaskTemplate(Map<String, dynamic> templateData) async {
    try {
      await _taskTemplatesCollection.add(templateData);
    } catch (e) {
      debugPrint('Error adding task template: $e');
      rethrow;
    }
  }

  static Future<void> updateAssignmentStatus(
      String assignmentId, String newStatus) async {
    try {
      await _assignmentsCollection.doc(assignmentId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final assignment = await _assignmentsCollection.doc(assignmentId).get();
      final data = assignment.data() as Map<String, dynamic>;
      await _updateTeamMemberStats(data['assignedToId']);
      final task = await _taskTemplatesCollection.doc(data['taskTemplateId']).get();
      final taskData = task.data() as Map<String, dynamic>;
      await _updateProjectStats(taskData['category']);
    } catch (e) {
      debugPrint('Error updating assignment status: $e');
      rethrow;
    }
  }

  static Future<void> deleteAssignment(String assignmentId) async {
    try {
      final assignment = await _assignmentsCollection.doc(assignmentId).get();
      final data = assignment.data() as Map<String, dynamic>;
      await _assignmentsCollection.doc(assignmentId).delete();
      await _updateTeamMemberStats(data['assignedToId']);
      final task = await _taskTemplatesCollection.doc(data['taskTemplateId']).get();
      final taskData = task.data() as Map<String, dynamic>;
      await _updateProjectStats(taskData['category']);
    } catch (e) {
      debugPrint('Error deleting assignment: $e');
      rethrow;
    }
  }

  static Future<void> addIssue(Map<String, dynamic> issueData) async {
    try {
      await _issuesCollection.add(issueData);
      await _updateTeamMemberStats(issueData['assignedTo']);
      if (issueData['projectId'] != null) {
        await _updateProjectStats(issueData['projectId']);
      }
      // TODO: Implement FCM notification
      debugPrint('Notification: Issue assigned to ${issueData['assignedTo']}');
    } catch (e) {
      debugPrint('Error adding issue: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getIssues() {
    return _issuesCollection.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> updateIssue(String issueId, Map<String, dynamic> issueData) async {
    try {
      await _issuesCollection.doc(issueId).update(issueData);
      await _updateTeamMemberStats(issueData['assignedTo']);
      if (issueData['projectId'] != null) {
        await _updateProjectStats(issueData['projectId']);
      }
      // TODO: Implement FCM notification
      debugPrint('Notification: Issue updated for ${issueData['assignedTo']}');
    } catch (e) {
      debugPrint('Error updating issue: $e');
      rethrow;
    }
  }

  static Future<void> deleteIssue(String issueId) async {
    try {
      final issue = await _issuesCollection.doc(issueId).get();
      final data = issue.data() as Map<String, dynamic>;
      await _issuesCollection.doc(issueId).delete();
      await _updateTeamMemberStats(data['assignedTo']);
      if (data['projectId'] != null) {
        await _updateProjectStats(data['projectId']);
      }
    } catch (e) {
      debugPrint('Error deleting issue: $e');
      rethrow;
    }
  }

  static Future<void> addProject(Map<String, dynamic> projectData) async {
    try {
      await _projectsCollection.add(projectData);
      for (var memberId in projectData['teamMembers']) {
        await _updateTeamMemberStats(memberId);
      }
      // TODO: Implement FCM notification
      debugPrint('Notification: Project assigned to ${projectData['teamMembers']}');
    } catch (e) {
      debugPrint('Error adding project: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getProjects() {
    return _projectsCollection.orderBy('createdAt', descending: true).snapshots();
  }

  static Future<void> updateProject(String projectId, Map<String, dynamic> projectData) async {
    try {
      await _projectsCollection.doc(projectId).update(projectData);
      for (var memberId in projectData['teamMembers']) {
        await _updateTeamMemberStats(memberId);
      }
      // TODO: Implement FCM notification
      debugPrint('Notification: Project updated for ${projectData['teamMembers']}');
    } catch (e) {
      debugPrint('Error updating project: $e');
      rethrow;
    }
  }

  static Future<void> deleteProject(String projectId) async {
    try {
      final project = await _projectsCollection.doc(projectId).get();
      final data = project.data() as Map<String, dynamic>;
      await _projectsCollection.doc(projectId).delete();
      for (var memberId in data['teamMembers']) {
        await _updateTeamMemberStats(memberId);
      }
    } catch (e) {
      debugPrint('Error deleting project: $e');
      rethrow;
    }
  }

  static Future<void> addProgressData(Map<String, dynamic> progressData) async {
    try {
      await _progressDataCollection.add(progressData);
    } catch (e) {
      debugPrint('Error adding progress data: $e');
      rethrow;
    }
  }

  static Stream<QuerySnapshot> getProgressData({String? projectId, String? timeRange}) {
    var query = _progressDataCollection.orderBy('createdAt', descending: true);
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }
    if (timeRange != null) {
      DateTime startDate;
      switch (timeRange) {
        case 'Monthly':
          startDate = DateTime.now().subtract(Duration(days: 30));
          break;
        case 'Quarterly':
          startDate = DateTime.now().subtract(Duration(days: 90));
          break;
        default: // Weekly
          startDate = DateTime.now().subtract(Duration(days: 7));
      }
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    return query.snapshots();
  }

  static Future<void> updateProgressData(String progressId, Map<String, dynamic> progressData) async {
    try {
      await _progressDataCollection.doc(progressId).update(progressData);
    } catch (e) {
      debugPrint('Error updating progress data: $e');
      rethrow;
    }
  }

  static Future<void> deleteProgressData(String progressId) async {
    try {
      await _progressDataCollection.doc(progressId).delete();
    } catch (e) {
      debugPrint('Error deleting progress data: $e');
      rethrow;
    }
  }

  static Future<void> _updateTeamMemberStats(String memberId) async {
    try {
      if (memberId.isEmpty) return;
      final tasksSnapshot = await _taskTemplatesCollection
          .where('assignedTo', isEqualTo: memberId)
          .get();
      final assignmentsSnapshot = await _assignmentsCollection
          .where('assignedToId', isEqualTo: memberId)
          .get();
      final issuesSnapshot = await _issuesCollection
          .where('assignedTo', isEqualTo: memberId)
          .get();

      final assignedTasks = tasksSnapshot.docs.length + assignmentsSnapshot.docs.length + issuesSnapshot.docs.length;
      final completedTasks = tasksSnapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .length +
          assignmentsSnapshot.docs
              .where((doc) => doc['status'] == 'completed')
              .length +
          issuesSnapshot.docs
              .where((doc) => doc['status'] == 'resolved')
              .length;
      final productivity = assignedTasks > 0 ? completedTasks / assignedTasks : 0.0;

      await _teamMembersCollection.doc(memberId).update({
        'assignedTasks': assignedTasks,
        'completedTasks': completedTasks,
        'productivity': productivity,
      });
    } catch (e) {
      debugPrint('Error updating team member stats: $e');
    }
  }

  static Future<void> _updateProjectStats(String projectId) async {
    try {
      if (projectId.isEmpty) return;
      final tasksSnapshot = await _taskTemplatesCollection
          .where('project', isEqualTo: projectId)
          .get();
      final totalTasks = tasksSnapshot.docs.length;
      final completedTasks = tasksSnapshot.docs
          .where((doc) => doc['status'] == 'completed')
          .length;
      final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

      await _projectsCollection.doc(projectId).update({
        'totalTasks': totalTasks,
        'completedTasks': completedTasks,
        'progress': progress,
      });
    } catch (e) {
      debugPrint('Error updating project stats: $e');
    }
  }

  static Future<void> cleanInvalidData() async {
    try {
      // Clean teamMembers
      final membersSnapshot = await _teamMembersCollection.get();
      for (var doc in membersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['name'] == null || data['name'].toString().isEmpty) {
          await doc.reference.delete();
          debugPrint('Deleted invalid team member: ${doc.id}');
        }
      }

      // Clean tasks
      final tasksSnapshot = await _taskTemplatesCollection.get();
      for (var doc in tasksSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['title'] == null || data['title'].toString().isEmpty) {
          await doc.reference.delete();
          debugPrint('Deleted invalid task: ${doc.id}');
        }
      }

      // Clean assignments
      final assignmentsSnapshot = await _assignmentsCollection.get();
      for (var doc in assignmentsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['title'] == null ||
            data['title'].toString().isEmpty ||
            data['assignedToId'] == null ||
            data['assignedToId'].toString().isEmpty ||
            data['taskTemplateId'] == null ||
            data['taskTemplateId'].toString().isEmpty) {
          await doc.reference.delete();
          debugPrint('Deleted invalid assignment: ${doc.id}');
        }
      }

      // Clean issues
      final issuesSnapshot = await _issuesCollection.get();
      for (var doc in issuesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['title'] == null || data['title'].toString().isEmpty) {
          await doc.reference.delete();
          debugPrint('Deleted invalid issue: ${doc.id}');
        }
      }

      // Clean projects
      final projectsSnapshot = await _projectsCollection.get();
      for (var doc in projectsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['name'] == null || data['name'].toString().isEmpty) {
          await doc.reference.delete();
          debugPrint('Deleted invalid project: ${doc.id}');
        }
      }

      // Clean progressData
      final progressSnapshot = await _progressDataCollection.get();
      for (var doc in progressSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['day'] == null || data['day'].toString().isEmpty) {
          await doc.reference.delete();
          debugPrint('Deleted invalid progress data: ${doc.id}');
        }
      }
    } catch (e) {
      debugPrint('Error cleaning invalid data: $e');
      rethrow;
    }
  }static Stream<QuerySnapshot> getNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  static Future<void> markNotificationAsRead(String notificationId) {
    return _firestore.collection('notifications').doc(notificationId).update({'isRead': true});
  }

  static Future<void> createNotification(TaskNotification notification) {
    return _firestore.collection('notifications').doc(notification.id).set(notification.toMap());
  }}
