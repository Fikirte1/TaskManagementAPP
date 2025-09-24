import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/screen/TaskListPage.dart';

class ProjectDetailPage extends StatelessWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const ProjectDetailPage({
    super.key,
    required this.projectId,
    required this.projectData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(projectData["name"] ?? "Project Detail"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              projectData["name"] ?? "No Name",
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 10),
            Text(
              projectData["description"] ?? "No description",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (projectData["deadline"] != null)
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Text(
                    "Deadline: ${projectData["deadline"].toDate().toString().split(' ')[0]}",
                    style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(Icons.person, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Created By: ${projectData["createdBy"] ?? 'Unknown'}",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ElevatedButton.icon(   
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskListPage(projectId: projectId),
      ),
    );
  },
  icon: const Icon(Icons.task),
  label: const Text("View Tasks"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blueAccent,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
)

          ],
        ),
      ),
    );
  }
}
