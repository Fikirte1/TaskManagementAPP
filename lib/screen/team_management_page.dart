import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/model/assignment_models.dart';
import 'package:task_management/service/assignment_service.dart';
import 'package:task_management/screen/AssignTasksPage.dart';

class TeamManagementPage extends StatefulWidget {
  const TeamManagementPage({super.key});

  @override
  State<TeamManagementPage> createState() => _TeamManagementPageState();
}

class _TeamManagementPageState extends State<TeamManagementPage> {
  List<TeamMember> _teamMembers = [];
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription<QuerySnapshot>? _membersSubscription;

  @override
  void initState() {
    super.initState();
    _loadTeamMembers();
  }

  @override
  void dispose() {
    _membersSubscription?.cancel();
    super.dispose();
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
            _isLoading = false;
            _errorMessage = members.isEmpty ? "No team members found" : null;
          });
        }
      },
      onError: (error) {
        debugPrint("Error loading team members: $error");
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load team members: $error";
        });
      },
    );
  }

  void _showAddTeamMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTeamMemberDialog(
        onTeamMemberAdded: () {
          // Refresh is handled by Firestore listener
        },
      ),
    );
  }

  void _deleteTeamMember(String memberId, String memberName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team Member'),
        content: Text('Are you sure you want to delete $memberName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('teamMembers')
                    .doc(memberId)
                    .delete();
                Navigator.pop(context);
                _showSnackBar('Team member deleted successfully', isError: false);
              } catch (e) {
                Navigator.pop(context);
                _showSnackBar('Error deleting team member: $e', isError: true);
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

  Widget _buildTeamMemberCard(TeamMember member) {
    final initial = member.name.isNotEmpty ? member.name[0] : "?";
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
          child: Text(
            initial,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          member.name.isNotEmpty ? member.name : "Unknown Member",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.role.isNotEmpty ? member.role : "No Role"),
            Text(member.email.isNotEmpty ? member.email : "No Email"),
            Text(
              "Joined: ${member.joinedDate.toLocal().toString().split(' ')[0]}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteTeamMember(member.id, member.name),
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
          const Text("Loading team members..."),
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
          const Icon(Icons.people_alt, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No Team Members",
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add team members to get started",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _showAddTeamMemberDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Add Team Member'),
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
          "Team Management",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            onPressed: _loadTeamMembers,
            tooltip: "Reload team members",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? _buildLoadingState()
            : _teamMembers.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: _teamMembers.length,
                    itemBuilder: (context, index) => _buildTeamMemberCard(_teamMembers[index]),
                  ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAddTeamMemberDialog,
            backgroundColor: const Color(0xFF2563EB),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AssignTasksPage()),
              );
            },
            backgroundColor: const Color(0xFF9333EA),
            child: const Icon(Icons.group_add),
          ),
        ],
      ),
    );
  }
}

class AddTeamMemberDialog extends StatefulWidget {
  final Function() onTeamMemberAdded;

  const AddTeamMemberDialog({super.key, required this.onTeamMemberAdded});

  @override
  State<AddTeamMemberDialog> createState() => _AddTeamMemberDialogState();
}

class _AddTeamMemberDialogState extends State<AddTeamMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _emailController = TextEditingController();
  DateTime _joinedDate = DateTime.now();

  void _pickJoinedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _joinedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _joinedDate = picked);
    }
  }

  void _addTeamMember() async {
    if (_formKey.currentState!.validate()) {
      try {
        final memberData = {
          'id': FirebaseFirestore.instance.collection('teamMembers').doc().id,
          'name': _nameController.text,
          'role': _roleController.text,
          'email': _emailController.text,
          'joinedDate': Timestamp.fromDate(_joinedDate),
        };

        await AssignmentService.addTeamMember(memberData);
        widget.onTeamMemberAdded();
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Team member added successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding team member: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Team Member'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(labelText: 'Role'),
                validator: (value) => value!.isEmpty ? 'Enter role' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) return 'Enter email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Joined Date: '),
                  TextButton(
                    onPressed: _pickJoinedDate,
                    child: Text('${_joinedDate.year}-${_joinedDate.month}-${_joinedDate.day}'),
                  ),
                ],
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
          onPressed: _addTeamMember,
          child: const Text('Add Member'),
        ),
      ],
    );
  }
}