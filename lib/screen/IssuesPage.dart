import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/model/assignment_models.dart';
import 'package:task_management/service/assignment_service.dart';

class IssuesPage extends StatefulWidget {
  const IssuesPage({super.key});

  @override
  State<IssuesPage> createState() => _IssuesPageState();
}

class _IssuesPageState extends State<IssuesPage> {
  List<Issue> _issues = [];
  List<TeamMember> _teamMembers = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _issuesSubscription;
  StreamSubscription<QuerySnapshot>? _teamMembersSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _issuesSubscription?.cancel();
    _teamMembersSubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    _loadTeamMembers();
    _loadIssues();
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

  void _loadIssues() {
    _issuesSubscription = AssignmentService.getIssues().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;
        final issues = snapshot.docs.map((doc) {
          try {
            return Issue.fromFirestore(doc);
          } catch (e) {
            debugPrint("Error parsing issue: $e");
            return null;
          }
        }).whereType<Issue>().toList();
        setState(() {
          _issues = issues;
          _checkIfDataLoaded();
        });
      },
      onError: (error) {
        debugPrint("Error loading issues: $error");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load issues";
            _checkIfDataLoaded();
          });
        }
      },
    );
  }

  void _checkIfDataLoaded() {
    if (_issues.isNotEmpty || _teamMembers.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddIssueDialog({Issue? issue}) {
    showDialog(
      context: context,
      builder: (context) => AddIssueDialog(
        teamMembers: _teamMembers,
        issue: issue,
        onIssueAdded: _loadIssues,
      ),
    );
  }

  void _deleteIssue(String issueId, String issueTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Issue'),
        content: Text('Are you sure you want to delete "$issueTitle"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await AssignmentService.deleteIssue(issueId);
                Navigator.pop(context);
                _showSnackBar('Issue deleted successfully', isError: false);
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error deleting issue: $e', isError: true);
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

  Widget _buildIssueCard(Issue issue) {
    final teamMember = _teamMembers.firstWhere(
      (member) => member.id == issue.assignedTo,
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade100, Colors.red.shade50],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.warning_amber_rounded,
            color: Colors.red,
            size: 20,
          ),
        ),
        title: Text(
          issue.title.isNotEmpty ? issue.title : "Untitled Issue",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(issue.description.isNotEmpty ? issue.description : "No description"),
            Text("Priority: ${issue.priority.toString().split('.').last}"),
            Text("Status: ${issue.status.toString().split('.').last}"),
            Text("Assigned to: ${teamMember.name}"),
            Text(
              "Created: ${issue.createdAt.toLocal().toString().split(' ')[0]}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            if (issue.dueDate != null)
              Text(
                "Due: ${issue.dueDate!.toLocal().toString().split(' ')[0]}",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            if (issue.projectId != null)
              Text(
                "Project: ${issue.projectId}",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showAddIssueDialog(issue: issue),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteIssue(issue.id, issue.title),
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
          const Text("Loading issues..."),
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
          const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No Issues",
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add issues to track problems",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showAddIssueDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Add Issue'),
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
          "Issue Tracking",
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
            tooltip: "Reload issues",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? _buildLoadingState()
            : _issues.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _issues.length,
                    itemBuilder: (context, index) => _buildIssueCard(_issues[index]),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIssueDialog(),
        backgroundColor: const Color(0xFFDC2626),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddIssueDialog extends StatefulWidget {
  final List<TeamMember> teamMembers;
  final Issue? issue;
  final Function() onIssueAdded;

  const AddIssueDialog({
    super.key,
    required this.teamMembers,
    this.issue,
    required this.onIssueAdded,
  });

  @override
  State<AddIssueDialog> createState() => _AddIssueDialogState();
}

class _AddIssueDialogState extends State<AddIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectIdController = TextEditingController();
  IssuePriority _priority = IssuePriority.low;
  IssueStatus _status = IssueStatus.open;
  String? _assignedTo;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.issue != null) {
      _titleController.text = widget.issue!.title;
      _descriptionController.text = widget.issue!.description;
      _projectIdController.text = widget.issue!.projectId ?? '';
      _priority = widget.issue!.priority;
      _status = widget.issue!.status;
      _assignedTo = widget.issue!.assignedTo;
      _dueDate = widget.issue!.dueDate;
    }
  }

  void _saveIssue() async {
    if (_formKey.currentState!.validate()) {
      try {
        final issueData = {
          'id': widget.issue?.id ?? FirebaseFirestore.instance.collection('issues').doc().id,
          'title': _titleController.text,
          'description': _descriptionController.text,
          'priority': _priority.toString().split('.').last,
          'status': _status.toString().split('.').last,
          'assignedTo': _assignedTo ?? '',
          'createdAt': widget.issue != null
              ? Timestamp.fromDate(widget.issue!.createdAt)
              : Timestamp.now(),
          'dueDate': _dueDate != null ? Timestamp.fromDate(_dueDate!) : null,
          'projectId': _projectIdController.text.isNotEmpty ? _projectIdController.text : null,
        };

        if (widget.issue != null) {
          await AssignmentService.updateIssue(widget.issue!.id, issueData);
        } else {
          await AssignmentService.addIssue(issueData);
        }
        widget.onIssueAdded();
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(
              widget.issue != null ? 'Issue updated successfully' : 'Issue added successfully',
              isError: false);
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Error ${widget.issue != null ? 'updating' : 'adding'} issue: $e',
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
      title: Text(widget.issue != null ? 'Edit Issue' : 'Add Issue'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Enter description' : null,
              ),
              TextFormField(
                controller: _projectIdController,
                decoration: const InputDecoration(labelText: 'Project ID (Optional)'),
              ),
              DropdownButtonFormField<IssuePriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: IssuePriority.values
                    .map((priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority.toString().split('.').last),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              DropdownButtonFormField<IssueStatus>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: IssueStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toString().split('.').last),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: _assignedTo,
                decoration: const InputDecoration(labelText: 'Assigned To'),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Unassigned'),
                  ),
                  ...widget.teamMembers.map((member) => DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      )),
                ],
                onChanged: (value) {
                  setState(() {
                    _assignedTo = value;
                  });
                },
              ),
              ListTile(
                title: Text(
                  _dueDate == null
                      ? 'Select Due Date'
                      : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _dueDate = pickedDate;
                    });
                  }
                },
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
          onPressed: _saveIssue,
          child: Text(widget.issue != null ? 'Update Issue' : 'Add Issue'),
        ),
      ],
    );
  }
}