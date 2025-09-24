import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskListPage extends StatefulWidget {
  final String projectId;
  const TaskListPage({super.key, required this.projectId});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔹 Add Task Dialog
  Future<void> _addTaskDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection("tasks").add({
                "projectId": widget.projectId,
                "title": titleController.text,
                "description": descController.text,
                "status": "Pending",
                "priority": "Normal",
                "createdAt": Timestamp.now(),
                "updatedAt": Timestamp.now(),
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // 🔹 Update Task Dialog
  Future<void> _updateTaskDialog(DocumentSnapshot task) async {
    final data = task.data() as Map<String, dynamic>;
    final titleController = TextEditingController(text: data["title"]);
    final descController = TextEditingController(text: data["description"]);
    String status = data["status"] ?? "Pending";

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            DropdownButton<String>(
              value: status,
              items: ["Pending", "In Progress", "Completed"]
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => status = val!),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _firestore.collection("tasks").doc(task.id).update({
                "title": titleController.text,
                "description": descController.text,
                "status": status,
                "updatedAt": Timestamp.now(),
              });
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // 🔹 Delete Task
  Future<void> _deleteTask(String taskId) async {
    await _firestore.collection("tasks").doc(taskId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Tasks"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection("tasks")
            .where("projectId", isEqualTo: widget.projectId)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No tasks found"));
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final data = task.data() as Map<String, dynamic>;

              return Dismissible(
                key: Key(task.id),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => _deleteTask(task.id),
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      Icons.task,
                      color: data["status"] == "Completed"
                          ? Colors.green
                          : Colors.orange,
                    ),
                    title: Text(data["title"] ?? "Untitled"),
                    subtitle: Text(data["description"] ?? ""),
                    trailing: Text(data["status"] ?? "Pending"),
                    onTap: () => _updateTaskDialog(task),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: _addTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
