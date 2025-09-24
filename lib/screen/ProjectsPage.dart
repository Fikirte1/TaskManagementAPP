import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/model/assignment_models.dart';
import 'package:task_management/service/assignment_service.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> {
  List<Project> _projects = [];
  List<TeamMember> _teamMembers = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _projectsSubscription;
  StreamSubscription<QuerySnapshot>? _teamMembersSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    _teamMembersSubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    _loadTeamMembers();
    _loadProjects();
  }

  void _loadTeamMembers() {
    _teamMembersSubscription = AssignmentService.getTeamMembers().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;
        final members = snapshot.docs.map((doc) {
          try {
            return TeamMember.fromFirestore(doc);
          } catch (e) {
            debugPrint("Error parsing team member: $e");
            return null;
          }
        }).whereType<TeamMember>().toList();
        setState(() {
          _teamMembers = members;
          _checkIfDataLoaded();
        });
      },
      onError: (error) {
        debugPrint("Error loading team members: $error");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load team members";
            _checkIfDataLoaded();
          });
        }
      },
    );
  }

  void _loadProjects() {
    _projectsSubscription = AssignmentService.getProjects().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;
        final projects = snapshot.docs.map((doc) {
          try {
            return Project.fromFirestore(doc);
          } catch (e) {
            debugPrint("Error parsing project: $e");
            return null;
          }
        }).whereType<Project>().toList();
        setState(() {
          _projects = projects;
          _checkIfDataLoaded();
        });
      },
      onError: (error) {
        debugPrint("Error loading projects: $error");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load projects";
            _checkIfDataLoaded();
          });
        }
      },
    );
  }

  void _checkIfDataLoaded() {
    if (_projects.isNotEmpty || _teamMembers.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddProjectDialog({Project? project}) {
    showDialog(
      context: context,
      builder: (context) => AddProjectDialog(
        teamMembers: _teamMembers,
        project: project,
        onProjectAdded: _loadProjects,
      ),
    );
  }

  void _deleteProject(String projectId, String projectName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "$projectName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await AssignmentService.deleteProject(projectId);
                Navigator.pop(context);
                _showSnackBar('Project deleted successfully', isError: false);
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error deleting project: $e', isError: true);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
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

  Widget _buildProjectCard(Project project) {
    final teamMemberNames = project.teamMembers.map((id) {
      final member = _teamMembers.firstWhere(
        (member) => member.id == id,
      orElse: () => TeamMember(
  id: '',
  name: 'Unknown Member',
  role: 'No Role',
  email: '',
  joinedDate: DateTime.now(),
  avatar: '', // Add this
  assignedTasks: 0,
  completedTasks: 0,
  productivity: 0.0,
),
      );
      return member.name;
    }).join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade100, Colors.blue.shade50],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.folder,
            color: Colors.blue,
            size: 20,
          ),
        ),
        title: Text(
          project.name.isNotEmpty ? project.name : "Untitled Project",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(project.description.isNotEmpty ? project.description : "No description"),
            Text("Team: ${teamMemberNames.isNotEmpty ? teamMemberNames : 'None'}"),
            Text(
              "Start: ${project.startDate.toLocal().toString().split(' ')[0]}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (project.endDate != null)
              Text(
                "End: ${project.endDate!.toLocal().toString().split(' ')[0]}",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showAddProjectDialog(project: project),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteProject(project.id, project.name),
            ),
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
          const Text("Loading projects..."),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.folder_open, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No Projects",
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add projects to organize tasks",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showAddProjectDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Add Project'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Projects",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            onPressed: _loadData,
            tooltip: "Reload projects",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? _buildLoadingState()
            : _projects.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _projects.length,
                    itemBuilder: (context, index) => _buildProjectCard(_projects[index]),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(),
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddProjectDialog extends StatefulWidget {
  final List<TeamMember> teamMembers;
  final Project? project;
  final Function() onProjectAdded;

  const AddProjectDialog({
    super.key,
    required this.teamMembers,
    this.project,
    required this.onProjectAdded,
  });

  @override
  State<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends State<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  List<String> _selectedTeamMembers = [];

  @override
  void initState() {
    super.initState();
    if (widget.project != null) {
      _nameController.text = widget.project!.name;
      _descriptionController.text = widget.project!.description;
      _startDate = widget.project!.startDate;
      _endDate = widget.project!.endDate;
      _selectedTeamMembers = widget.project!.teamMembers;
    }
  }

  void _saveProject() async {
    if (_formKey.currentState!.validate()) {
      try {
        final projectData = {
          'id': widget.project?.id ?? FirebaseFirestore.instance.collection('projects').doc().id,
          'name': _nameController.text,
          'description': _descriptionController.text,
          'startDate': Timestamp.fromDate(_startDate),
          'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
          'teamMembers': _selectedTeamMembers,
          'createdAt': widget.project != null
              ? Timestamp.fromDate(widget.project!.createdAt)
              : Timestamp.now(),
        };

        if (widget.project != null) {
          await AssignmentService.updateProject(widget.project!.id, projectData);
        } else {
          await AssignmentService.addProject(projectData);
        }
        widget.onProjectAdded();
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(
              widget.project != null ? 'Project updated successfully' : 'Project added successfully',
              isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error ${widget.project != null ? 'updating' : 'adding'} project: $e',
              isError: true);
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.project != null ? 'Edit Project' : 'Add Project'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) => value!.isEmpty ? 'Enter project name' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Enter description' : null,
              ),
              ListTile(
                title: Text(
                  'Start: ${_startDate.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _startDate = pickedDate;
                    });
                  }
                },
              ),
              ListTile(
                title: Text(
                  _endDate == null
                      ? 'Select End Date (Optional)'
                      : 'End: ${_endDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _endDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _endDate = pickedDate;
                    });
                  }
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Add Team Member'),
                items: widget.teamMembers
                    .map((member) => DropdownMenuItem(
                          value: member.id,
                          child: Text(member.name),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null && !_selectedTeamMembers.contains(value)) {
                    setState(() {
                      _selectedTeamMembers.add(value);
                    });
                  }
                },
              ),
              Wrap(
                spacing: 8,
                children: _selectedTeamMembers.map((id) {
                  final member = widget.teamMembers.firstWhere(
                    (m) => m.id == id,
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
                  return Chip(
                    label: Text(member.name),
                    onDeleted: () {
                      setState(() {
                        _selectedTeamMembers.remove(id);
                      });
                    },
                  );
                }).toList(),
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
          onPressed: _saveProject,
          child: Text(widget.project != null ? 'Update Project' : 'Add Project'),
        ),
      ],
    );
  }
}