import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String status = "pending";
  String priority = "medium";
  DateTime? dueDate;

  Future<void> addTask() async {
    if (titleController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection("tasks").add({
      "title": titleController.text,
      "description": descriptionController.text,
      "status": status,
      "priority": priority,
      "dueDate": dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      "createdAt": Timestamp.now(),
      "updatedAt": Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Task Added Successfully")),
    );

    Navigator.pop(context); // go back after adding
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Task")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            DropdownButton<String>(
              value: status,
              onChanged: (value) => setState(() => status = value!),
              items: const [
                DropdownMenuItem(value: "pending", child: Text("Pending")),
                DropdownMenuItem(value: "in-progress", child: Text("In Progress")),
                DropdownMenuItem(value: "completed", child: Text("Completed")),
              ],
            ),
            DropdownButton<String>(
              value: priority,
              onChanged: (value) => setState(() => priority = value!),
              items: const [
                DropdownMenuItem(value: "low", child: Text("Low")),
                DropdownMenuItem(value: "medium", child: Text("Medium")),
                DropdownMenuItem(value: "high", child: Text("High")),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    dueDate = picked;
                  });
                }
              },
              child: Text(dueDate == null
                  ? "Select Due Date"
                  : "Due Date: ${dueDate!.toLocal()}".split(' ')[0]),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: addTask,
              child: const Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }
}
