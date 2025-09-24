import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:task_management/service/assignment_service.dart';
import 'package:task_management/model/assignment_models.dart';

class AssignTasksPage extends StatefulWidget {
  const AssignTasksPage({super.key});

  @override
  State<AssignTasksPage> createState() => _AssignTasksPageState();
}

class _AssignTasksPageState extends State<AssignTasksPage> {
  TeamMember? _selectedMember;
  TaskTemplate? _selectedTemplate;
  DateTime? _selectedDueDate;
  String _customInstructions = "";

  List<TeamMember> _teamMembers = [];
  List<TaskTemplate> _taskTemplates = [];
  List<Assignment> _assignments = [];

  bool _isLoading = true;
  bool _hasData = false;
  String? _errorMessage;

  StreamSubscription<QuerySnapshot>? _membersSubscription;
  StreamSubscription<QuerySnapshot>? _templatesSubscription;
  StreamSubscription<QuerySnapshot>? _assignmentsSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    _templatesSubscription?.cancel();
    _assignmentsSubscription?.cancel();
    super.dispose();
  }

  Future<bool> _isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  void _loadData() async {
    if (!await _isConnected()) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No internet connection, loading sample data";
          _loadSampleData();
        });
      }
      return;
    }

    _loadTeamMembers();
    _loadTaskTemplates();
    _loadAssignments();

    // Set timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
      if (_isLoading && mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Timeout loading data. Check your connection.";
          _loadSampleData();
        });
      }
    });
  }

  void _loadTeamMembers() {
    _membersSubscription = AssignmentService.getTeamMembers().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;

        final members = snapshot.docs.map((doc) {
          try {
            final member = TeamMember.fromFirestore(doc);
            return member.name != 'Unknown Member' ? member : null;
          } catch (e) {
            debugPrint("Error parsing team member: $e");
            return null;
          }
        }).whereType<TeamMember>().toList();

        if (mounted) {
          setState(() {
            _teamMembers = members;
            _checkIfDataLoaded();
          });
        }
      },
      onError: (error) {
        debugPrint("Error loading team members: $error");
        if (!mounted) return;
        setState(() {
          _errorMessage = "Failed to load team members";
          _checkIfDataLoaded();
        });
      },
    );
  }

  void _loadTaskTemplates() {
    _templatesSubscription = AssignmentService.getTaskTemplates().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;

        final templates = snapshot.docs.map((doc) {
          try {
            final task = Task.fromFirestore(doc);
            if (task.title.isEmpty || task.status != TaskStatus.todo) return null; // Only include 'todo' tasks
            return TaskTemplate.fromTask(task);
          } catch (e) {
            debugPrint("Error parsing task: $e");
            return null;
          }
        }).whereType<TaskTemplate>().toList();

        if (mounted) {
          setState(() {
            _taskTemplates = templates;
            _checkIfDataLoaded();
          });
        }
      },
      onError: (error) {
        debugPrint("Error loading tasks: $error");
        if (!mounted) return;
        setState(() {
          _errorMessage = "Failed to load tasks";
          _checkIfDataLoaded();
        });
      },
    );
  }

  void _loadAssignments() {
    _assignmentsSubscription = AssignmentService.getAssignments().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;

        final assignments = snapshot.docs.map((doc) {
          try {
            final assignment = Assignment.fromFirestore(doc);
            return assignment.title != 'Untitled Assignment' ? assignment : null;
          } catch (e) {
            debugPrint("Error parsing assignment: $e");
            return null;
          }
        }).whereType<Assignment>().toList();

        if (mounted) {
          setState(() {
            _assignments = assignments;
            _checkIfDataLoaded();
          });
        }
      },
      onError: (error) {
        debugPrint("Error loading assignments: $error");
        if (!mounted) return;
        setState(() {
          _errorMessage = "Failed to load assignments";
          _checkIfDataLoaded();
        });
      },
    );
  }

  void _checkIfDataLoaded() {
    if (_teamMembers.isNotEmpty || _taskTemplates.isNotEmpty || _assignments.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasData = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasData = false;
          _loadSampleData();
        });
      }
    }
  }

  void _loadSampleData() {
    debugPrint("Loading sample data as fallback...");

    if (mounted) {
      setState(() {
        _teamMembers = [
          TeamMember(
  id: 'member1',
  name: 'Alice Johnson',
  role: 'Developer',
  email: 'alice@example.com',
  joinedDate: DateTime(2023, 1, 15),
  avatar: 'AJ', // Add initials or empty string
  assignedTasks: 3,
  completedTasks: 2,
  productivity: 0.67,
),
         TeamMember(
  id: 'member1',
  name: 'Alice Johnson',
  role: 'Developer',
  email: 'alice@example.com',
  joinedDate: DateTime(2023, 1, 15),
  avatar: 'AJ', // Add initials or empty string
  assignedTasks: 3,
  completedTasks: 2,
  productivity: 0.67,
),
         TeamMember(
  id: 'member1',
  name: 'Alice Johnson',
  role: 'Developer',
  email: 'alice@example.com',
  joinedDate: DateTime(2023, 1, 15),
  avatar: 'AJ', // Add initials or empty string
  assignedTasks: 3,
  completedTasks: 2,
  productivity: 0.67,
),
        ];

        _taskTemplates = [
          TaskTemplate.fromTask(Task(
            id: 'sample-task-1',
            title: "UI/UX Design",
            description: "Design modern and responsive user interfaces",
            project: "Design",
            assignedTo: "",
            dueDate: DateTime.now().add(const Duration(days: 7)),
            priority: TaskPriority.medium,
            status: TaskStatus.todo,
            createdAt: DateTime.now(),
          )),
          TaskTemplate.fromTask(Task(
            id: 'sample-task-2',
            title: "API Integration",
            description: "Connect frontend application with backend APIs",
            project: "Development",
            assignedTo: "",
            dueDate: DateTime.now().add(const Duration(days: 5)),
            priority: TaskPriority.high,
            status: TaskStatus.todo,
            createdAt: DateTime.now(),
          )),
          TaskTemplate.fromTask(Task(
            id: 'sample-task-3',
            title: "Testing & QA",
            description: "Perform comprehensive testing and quality assurance",
            project: "Testing",
            assignedTo: "",
            dueDate: DateTime.now().add(const Duration(days: 3)),
            priority: TaskPriority.low,
            status: TaskStatus.todo,
            createdAt: DateTime.now(),
          )),
        ];

        _assignments = [
          Assignment(
            id: 'sample-assignment-1',
            taskTemplateId: 'sample-task-1',
            assignedToId: 'sample-1',
            title: "UI/UX Design",
            description: "Design modern and responsive user interfaces",
            dueDate: DateTime.now().add(const Duration(days: 7)),
            assignedAt: DateTime.now(),
            status: AssignmentStatus.assigned,
            customInstructions: "Focus on mobile-first design",
          ),
          Assignment(
            id: 'sample-assignment-2',
            taskTemplateId: 'sample-task-2',
            assignedToId: 'sample-2',
            title: "API Integration",
            description: "Connect frontend application with backend APIs",
            dueDate: DateTime.now().add(const Duration(days: 5)),
            assignedAt: DateTime.now().subtract(const Duration(days: 2)),
            status: AssignmentStatus.inProgress,
            customInstructions: "Ensure OAuth2 authentication",
          ),
        ];

        _isLoading = false;
        _hasData = true;
      });
    }
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      initialDate: _selectedDueDate ?? now.add(const Duration(days: 7)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _assignTask() async {
    if (_selectedMember == null || _selectedTemplate == null) {
      _showSnackBar("Please select a team member and a task template", isError: true);
      return;
    }

    if (_selectedDueDate == null) {
      _showSnackBar("Please select a due date", isError: true);
      return;
    }

    if (!await _isConnected()) {
      _showSnackBar("No internet connection", isError: true);
      return;
    }

    try {
      final assignment = Assignment(
        id: '',
        taskTemplateId: _selectedTemplate!.id,
        assignedToId: _selectedMember!.id,
        title: _selectedTemplate!.title,
        description: _selectedTemplate!.description,
        dueDate: _selectedDueDate!,
        assignedAt: DateTime.now(),
        customInstructions: _customInstructions,
      );

      await AssignmentService.addAssignment(assignment.toMap());

      _showSnackBar(
        "Task '${_selectedTemplate!.title}' assigned to ${_selectedMember!.name} due on ${_selectedDueDate!.toLocal().toString().split(' ')[0]} ✅",
        isError: false,
      );

      _resetForm();
    } catch (e) {
      _showSnackBar("Error assigning task: $e", isError: true);
    }
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _selectedMember = null;
        _selectedTemplate = null;
        _selectedDueDate = null;
        _customInstructions = "";
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildMemberCard(TeamMember member) {
    final isSelected = _selectedMember?.id == member.id;
    final displayName = member.name.isNotEmpty ? member.name : "Unknown Member";
    final initial = member.name.isNotEmpty ? member.name[0] : "?";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            initial,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(displayName),
        subtitle: Text(member.role.isNotEmpty ? member.role : "No Role"),
        trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
        onTap: () => setState(() => _selectedMember = isSelected ? null : member),
      ),
    );
  }

  Widget _buildTaskCard(TaskTemplate task) {
    final isSelected = _selectedTemplate?.id == task.id;
    final displayTitle = task.title.isNotEmpty ? task.title : "Untitled Task";
    final displayDescription = task.description.isNotEmpty ? task.description : "No description";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: isSelected ? Colors.green[50] : null,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.task, size: 20, color: Colors.green),
        ),
        title: Text(displayTitle),
        subtitle: Text(displayDescription),
        trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
        onTap: () => setState(() => _selectedTemplate = isSelected ? null : task),
      ),
    );
  }

  Widget _buildAssignmentCard(Assignment assignment) {
    final assignedMember = _teamMembers.firstWhere(
      (member) => member.id == assignment.assignedToId,
     orElse: () => TeamMember(
  id: '',
  name: 'Unknown',
  role: '',
  email: '',
  joinedDate: DateTime.now(),
  avatar: '', // Add this
  assignedTasks: 0,
  completedTasks: 0,
  productivity: 0.0,
),
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.assignment, size: 20, color: Colors.orange),
        ),
        title: Text(assignment.title.isNotEmpty ? assignment.title : "Untitled Assignment"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Assigned to: ${assignedMember.name}"),
            Text("Due: ${assignment.dueDate.toLocal().toString().split(' ')[0]}"),
            Text("Status: ${assignment.status.toString().split('.').last}"),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text("Loading data..."),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text("Retry"),
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
          const Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No data available"),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadSampleData,
            child: const Text("Load Sample Data"),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Team Members Section
          SizedBox(
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Team Members",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _teamMembers.isEmpty
                      ? const Center(child: Text("No team members available"))
                      : ListView.builder(
                          itemCount: _teamMembers.length,
                          itemBuilder: (context, index) => _buildMemberCard(_teamMembers[index]),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Task Templates Section
          SizedBox(
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Task Templates",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _taskTemplates.isEmpty
                      ? const Center(child: Text("No task templates available"))
                      : ListView.builder(
                          itemCount: _taskTemplates.length,
                          itemBuilder: (context, index) => _buildTaskCard(_taskTemplates[index]),
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Assignments Section
          SizedBox(
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Assigned Tasks",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _assignments.isEmpty
                      ? const Center(child: Text("No tasks assigned"))
                      : ListView.builder(
                          itemCount: _assignments.length,
                          itemBuilder: (context, index) => _buildAssignmentCard(_assignments[index]),
                        ),
                ),
              ],
            ),
          ),

          // Selection Summary
          if (_selectedMember != null || _selectedTemplate != null)
            _buildSelectionSummary(),
        ],
      ),
    );
  }

  Widget _buildSelectionSummary() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Ready to Assign",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_selectedMember != null)
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Assigned to: ${_selectedMember!.name}")),
                ],
              ),
            if (_selectedTemplate != null)
              Row(
                children: [
                  const Icon(Icons.task, size: 20, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Task: ${_selectedTemplate!.title}")),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedDueDate == null
                        ? "No due date selected"
                        : "Due: ${_selectedDueDate!.toLocal().toString().split(' ')[0]}",
                    style: TextStyle(
                      color: _selectedDueDate == null ? Colors.red : Colors.black,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _pickDueDate,
                  child: Text(
                    _selectedDueDate == null ? "Select Due Date" : "Change Due Date",
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Custom Instructions",
                border: OutlineInputBorder(),
                hintText: "Add any specific requirements or notes...",
              ),
              onChanged: (val) => _customInstructions = val,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _assignTask,
                    icon: const Icon(Icons.send),
                    label: const Text("Assign Task"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assign Tasks"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: "Reload data",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? _buildLoadingState()
            : _hasData
                ? _buildContent()
                : _buildEmptyState(),
      ),
    );
  }
}