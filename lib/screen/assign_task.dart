import 'package:flutter/material.dart';

class AssignTaskPage extends StatefulWidget {
  const AssignTaskPage({super.key});

  @override
  State<AssignTaskPage> createState() => _AssignTaskPageState();
}

class _AssignTaskPageState extends State<AssignTaskPage> {
  final taskController = TextEditingController();
  String? selectedUser;

  final users = ["Alice", "Bob", "Charlie"]; // Replace with Firebase users

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Task"),
        backgroundColor: Colors.purple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: taskController,
              decoration: const InputDecoration(
                labelText: "Task Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: selectedUser,
              items: users
                  .map((user) => DropdownMenuItem(
                        value: user,
                        child: Text(user),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => selectedUser = value),
              decoration: const InputDecoration(
                  labelText: "Assign To", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Save task assignment to Firebase
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Task Assigned!")),
                );
              },
              child: const Text("Assign Task"),
            ),
          ],
        ),
      ),
    );
  }
}
