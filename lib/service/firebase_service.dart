import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _tasksCollection = _firestore.collection('tasks');

  // Add a new task to Firestore
  static Future<String> addTask(Map<String, dynamic> taskData) async {
    try {
      DocumentReference docRef = await _tasksCollection.add(taskData);
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding task: $e');
      throw e;
    }
  }

  // Get all tasks
  static Stream<QuerySnapshot> getTasks() {
    return _tasksCollection.orderBy('createdAt', descending: true).snapshots();
  }

  // Get tasks by status
  static Stream<QuerySnapshot> getTasksByStatus(String status) {
    return _tasksCollection
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Update task status
  static Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating task status: $e');
      throw e;
    }
  }

  // Update entire task
  static Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _tasksCollection.doc(taskId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating task: $e');
      throw e;
    }
  }

  // Delete task
  static Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      throw e;
    }
  }

  // Get task by ID
  static Future<DocumentSnapshot> getTaskById(String taskId) async {
    try {
      return await _tasksCollection.doc(taskId).get();
    } catch (e) {
      debugPrint('Error getting task: $e');
      throw e;
    }
  }
}