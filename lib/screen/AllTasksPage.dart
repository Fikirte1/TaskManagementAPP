import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Task Model
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
}

enum TaskPriority { low, medium, high, urgent }
enum TaskStatus { todo, inProgress, review, completed }

// Extension to copy Task with new status
extension TaskCopyWith on Task {
  Task copyWith({TaskStatus? status}) {
    return Task(
      id: id,
      title: title,
      description: description,
      project: project,
      assignedTo: assignedTo,
      dueDate: dueDate,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class AllTasksPage extends StatefulWidget {
  const AllTasksPage({super.key});

  @override
  State<AllTasksPage> createState() => _AllTasksPageState();
}

class _AllTasksPageState extends State<AllTasksPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  String _searchQuery = '';
  TaskStatus _currentFilter = TaskStatus.todo;
  bool _isGridView = false;
  StreamSubscription<QuerySnapshot>? _taskSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _listenToTasks();
  }

  // Real-time Firestore listener
  void _listenToTasks() {
    _taskSubscription = FirebaseFirestore.instance.collection('tasks').snapshots().listen(
      (snapshot) {
        print('Received ${snapshot.docs.length} tasks from Firestore');
        final tasks = snapshot.docs.map((doc) {
          final data = doc.data();
          print('Task data: $data');
          try {
            return Task(
              id: doc.id, // Use Firestore document ID
              title: data['title'] ?? '',
              description: data['description'] ?? '',
              project: data['project'] ?? '',
              assignedTo: data['assignedTo'] ?? '',
              dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
              priority: TaskPriority.values.firstWhere(
                (p) => p.toString().split('.').last.toLowerCase() == (data['priority']?.toLowerCase() ?? 'low'),
                orElse: () => TaskPriority.low,
              ),
              status: TaskStatus.values.firstWhere(
                (s) => s.toString().split('.').last.toLowerCase() == (data['status']?.toLowerCase() ?? 'todo'),
                orElse: () => TaskStatus.todo,
              ),
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            );
          } catch (e) {
            print('Error parsing task ${doc.id}: $e');
            return null;
          }
        }).where((task) => task != null).cast<Task>().toList();

        setState(() {
          _tasks = tasks;
          print('Updated tasks: ${_tasks.length}');
        });
        _filterTasks();
      },
      onError: (error) {
        print('Firestore listener error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching tasks: $error')),
        );
      },
    );
  }

  void _filterTasks() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _filteredTasks = _tasks.where((task) => task.status == _currentFilter).toList();
      } else {
        _filteredTasks = _tasks.where((task) =>
            task.status == _currentFilter &&
            (task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                task.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                task.project.toLowerCase().contains(_searchQuery.toLowerCase()))).toList();
      }
      print('Filtered tasks: ${_filteredTasks.length} for status $_currentFilter');
    });
  }

  void _onSearchChanged(String query) {
    _searchQuery = query;
    _filterTasks();
  }

  void _onFilterChanged(TaskStatus status) {
    _currentFilter = status;
    _filterTasks();
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TaskDetailsSheet(task: task, onStatusChanged: _updateTaskStatus),
    );
  }

  Future<void> _updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      final taskIndex = _tasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(status: newStatus);

        // Update Firestore
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
          'status': newStatus.toString().split('.').last,
          'updatedAt': Timestamp.now(),
        });

        _filterTasks();
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error updating task status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update task: $e')),
      );
    }
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTaskDialog(onTaskAdded: (task) {
        // Handled by Firestore listener
      }),
    );
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.urgent:
        return Colors.purple;
    }
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.review:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'Review';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'All Tasks',
          style: TextStyle(color: Color(0xFF1F2937), fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: const Color(0xFF6B7280)),
            onPressed: _toggleView,
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6B7280)),
            onPressed: _showAddTaskDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                onChanged: _onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),

          // Status Filter Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF2563EB),
              tabs: [
                Tab(text: 'To Do (${_tasks.where((t) => t.status == TaskStatus.todo).length})'),
                Tab(text: 'In Progress (${_tasks.where((t) => t.status == TaskStatus.inProgress).length})'),
                Tab(text: 'Review (${_tasks.where((t) => t.status == TaskStatus.review).length})'),
                Tab(text: 'Completed (${_tasks.where((t) => t.status == TaskStatus.completed).length})'),
              ],
              onTap: (index) => _onFilterChanged(TaskStatus.values[index]),
            ),
          ),

          // Tasks List/Grid
          Expanded(
            child: _filteredTasks.isEmpty
                ? _buildEmptyState()
                : _isGridView
                    ? _buildGridView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No tasks found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty ? 'Try adjusting your search terms' : 'Create your first task to get started',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _showAddTaskDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Add New Task'),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) {
        final task = _filteredTasks[index];
        return _buildTaskGridCard(task);
      },
    );
  }

  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getStatusColor(task.status).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.task_alt, color: _getStatusColor(task.status)),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(task.project, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(task.assignedTo, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getPriorityColor(task.priority).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.priority.toString().split('.').last.toUpperCase(),
                style: TextStyle(
                  color: _getPriorityColor(task.priority),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '${task.dueDate.difference(DateTime.now()).inDays}d',
              style: TextStyle(
                color: task.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        onTap: () => _showTaskDetails(task),
      ),
    );
  }

  Widget _buildTaskGridCard(Task task) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.task_alt, size: 16, color: _getStatusColor(task.status)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.priority.toString().split('.').last[0].toUpperCase(),
                      style: TextStyle(
                        color: _getPriorityColor(task.priority),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                task.project,
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      task.assignedTo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${task.dueDate.difference(DateTime.now()).inDays}d',
                    style: TextStyle(
                      color: task.dueDate.isBefore(DateTime.now()) ? Colors.red : Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getStatusText(task.status),
                    style: TextStyle(
                      color: _getStatusColor(task.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------
// Task Details Sheet
// --------------------
class TaskDetailsSheet extends StatelessWidget {
  final Task task;
  final Function(String, TaskStatus) onStatusChanged;

  const TaskDetailsSheet({super.key, required this.task, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(task.project, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 16),
          Text(task.description, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          const SizedBox(height: 24),
          const Text('Assigned To', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(task.assignedTo, style: TextStyle(color: Colors.grey[700])),
          const SizedBox(height: 24),
          const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            task.priority.toString().split('.').last.toUpperCase(),
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: TaskStatus.values.map((status) {
              return ChoiceChip(
                label: Text(status.toString().split('.').last),
                selected: task.status == status,
                onSelected: (_) => onStatusChanged(task.id, status),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// --------------------
// Add Task Dialog
// --------------------
class AddTaskDialog extends StatefulWidget {
  final Function(Task) onTaskAdded;

  const AddTaskDialog({super.key, required this.onTaskAdded});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectController = TextEditingController();
  final _assignedToController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 1));
  TaskPriority _priority = TaskPriority.low;

  void _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _addTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        final taskId = FirebaseFirestore.instance.collection('tasks').doc().id;
        final now = DateTime.now();

        final newTask = Task(
          id: taskId,
          title: _titleController.text,
          description: _descriptionController.text,
          project: _projectController.text,
          assignedTo: _assignedToController.text,
          dueDate: _dueDate,
          priority: _priority,
          status: TaskStatus.todo,
          createdAt: now,
        );

        await FirebaseFirestore.instance.collection('tasks').doc(taskId).set({
          'title': newTask.title,
          'description': newTask.description,
          'project': newTask.project,
          'assignedTo': newTask.assignedTo,
          'dueDate': Timestamp.fromDate(newTask.dueDate),
          'priority': newTask.priority.toString().split('.').last,
          'status': newTask.status.toString().split('.').last,
          'createdAt': Timestamp.fromDate(newTask.createdAt),
          'updatedAt': Timestamp.fromDate(newTask.createdAt),
        });

        print('Task added with ID: $taskId');
        widget.onTaskAdded(newTask);
        Navigator.pop(context);
      } catch (e) {
        print('Error adding task: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add task: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => v!.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                controller: _projectController,
                decoration: const InputDecoration(labelText: 'Project'),
                validator: (v) => v!.isEmpty ? 'Enter project' : null,
              ),
              TextFormField(
                controller: _assignedToController,
                decoration: const InputDecoration(labelText: 'Assigned To'),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Due Date: '),
                  TextButton(
                    onPressed: _pickDueDate,
                    child: Text('${_dueDate.year}-${_dueDate.month}-${_dueDate.day}'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: TaskPriority.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toString().split('.').last.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (p) => setState(() => _priority = p!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addTask,
          child: const Text('Add Task'),
        ),
      ],
    );
  }
}