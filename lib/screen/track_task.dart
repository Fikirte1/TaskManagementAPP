import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/screen/project_detail_page.dart'; // Make sure this path is correct

class TrackTaskPage extends StatelessWidget {
  const TrackTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Projects"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("projects")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No projects found"));
          }

          final projects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final data = project.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  title: Text(
                    data["name"] ?? "No Name",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (data["description"] != null)
                        Text(data["description"]),
                      const SizedBox(height: 5),
                      if (data["deadline"] != null)
                        Text(
                          "Deadline: ${data["deadline"].toDate().toString().split(' ')[0]}",
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                 onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProjectDetailPage(
        projectId: project.id,
        projectData: data,
      ),
    ),
  );
},

                ),
              );
            },
          );
        },
      ),
    );
  }
}
