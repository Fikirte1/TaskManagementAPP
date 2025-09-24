import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_management/model/assignment_models.dart';
import 'package:task_management/service/assignment_service.dart';
import 'AssignTasksPage.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Task> _tasks = [];
  List<Assignment> _assignments = [];
  List<TeamMember> _teamMembers = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _filterType = 'All'; // Filter: All, Status, or Team Member ID
  String? _filterValue; // Specific status or team member ID
  StreamSubscription<QuerySnapshot>? _tasksSubscription;
  StreamSubscription<QuerySnapshot>? _assignmentsSubscription;
  StreamSubscription<QuerySnapshot>? _teamMembersSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    _assignmentsSubscription?.cancel();
    _teamMembersSubscription?.cancel();
    super.dispose();
  }

  void _loadData() {
    _loadTeamMembers();
    _loadTasks();
    _loadAssignments();
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

  void _loadTasks() {
    _tasksSubscription = AssignmentService.getTaskTemplates().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;
        final tasks = snapshot.docs.map((doc) {
          try {
            return Task.fromFirestore(doc);
          } catch (e) {
            debugPrint("Error parsing task: $e");
            return null;
          }
        }).whereType<Task>().toList();
        setState(() {
          _tasks = tasks;
          _checkIfDataLoaded();
        });
      },
      onError: (error) {
        debugPrint("Error loading tasks: $error");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load tasks";
            _checkIfDataLoaded();
          });
        }
      },
    );
  }

  void _loadAssignments() {
    _assignmentsSubscription = AssignmentService.getAssignments().listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;
        final assignments = snapshot.docs.map((doc) {
          try {
            return Assignment.fromFirestore(doc);
          } catch (e) {
            debugPrint("Error parsing assignment: $e");
            return null;
          }
        }).whereType<Assignment>().toList();
        setState(() {
          _assignments = assignments;
          _checkIfDataLoaded();
        });
      },
      onError: (error) {
        debugPrint("Error loading assignments: $error");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load assignments";
            _checkIfDataLoaded();
          });
        }
      },
    );
  }

  void _checkIfDataLoaded() {
    if (_tasks.isNotEmpty || _assignments.isNotEmpty || _teamMembers.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final events = <dynamic>[];
    for (var task in _tasks) {
      if (isSameDay(task.dueDate, day)) {
        events.add(task);
      }
    }
    for (var assignment in _assignments) {
      if (isSameDay(assignment.dueDate, day)) {
        events.add(assignment);
      }
    }
    return events;
  }

  List<dynamic> _getFilteredItems() {
    final items = [..._tasks, ..._assignments];
    if (_filterType == 'All') {
      return items;
    } else if (_filterType == 'Status') {
      return items.where((item) {
        if (item is Task) {
          return item.status.toString().split('.').last == _filterValue;
        } else if (item is Assignment) {
          return item.status.toString().split('.').last == _filterValue;
        }
        return false;
      }).toList();
    } else if (_filterType == 'Team Member') {
      return items.where((item) {
        if (item is Task) {
          return item.assignedTo == _filterValue;
        } else if (item is Assignment) {
          return item.assignedToId == _filterValue;
        }
        return false;
      }).toList();
    }
    return items;
  }

  Widget _buildEventCard(dynamic item) {
    final isTask = item is Task;
    final title = isTask ? item.title : item.title;
    final description = isTask ? item.description : item.description;
    final dueDate = isTask ? item.dueDate : item.dueDate;
    final status = isTask
        ? item.status.toString().split('.').last
        : item.status.toString().split('.').last;
    final assignedToId = isTask ? item.assignedTo : item.assignedToId;
    final teamMember = _teamMembers.firstWhere(
      (member) => member.id == assignedToId,
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
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade100, Colors.orange.shade50],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isTask ? Icons.task : Icons.assignment,
            color: Colors.orange,
            size: 20,
          ),
        ),
        title: Text(
          title.isNotEmpty ? title : "Untitled",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description.isNotEmpty ? description : "No description"),
            Text("Due: ${dueDate.toLocal().toString().split(' ')[0]}"),
            Text("Status: $status"),
            Text("Assigned to: ${teamMember.name}"),
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
          const Text("Loading schedule..."),
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
          const Icon(Icons.calendar_today, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            "No Tasks or Assignments",
            style: TextStyle(fontSize: 24, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            "Add tasks to view the schedule",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AssignTasksPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9333EA),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Assign Tasks'),
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
          "Schedule & Deadlines",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          DropdownButton<String>(
            value: _filterType,
            items: [
              const DropdownMenuItem(value: 'All', child: Text('All')),
              const DropdownMenuItem(value: 'Status', child: Text('Filter by Status')),
              const DropdownMenuItem(value: 'Team Member', child: Text('Filter by Team Member')),
            ],
            onChanged: (value) {
              setState(() {
                _filterType = value!;
                _filterValue = null;
              });
            },
          ),
          if (_filterType == 'Status')
            DropdownButton<String>(
              value: _filterValue,
              hint: const Text('Select Status'),
              items: TaskStatus.values
                  .map((status) => DropdownMenuItem(
                        value: status.toString().split('.').last,
                        child: Text(status.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _filterValue = value;
                });
              },
            ),
          if (_filterType == 'Team Member')
            DropdownButton<String>(
              value: _filterValue,
              hint: const Text('Select Team Member'),
              items: _teamMembers
                  .map((member) => DropdownMenuItem(
                        value: member.id,
                        child: Text(member.name),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _filterValue = value;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6B7280)),
            onPressed: _loadData,
            tooltip: "Reload schedule",
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : (_tasks.isEmpty && _assignments.isEmpty)
              ? _buildEmptyState()
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          eventLoader: _getEventsForDay,
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: BoxDecoration(
                              color: const Color(0xFF9333EA),
                              shape: BoxShape.circle,
                            ),
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Tasks and Assignments",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _getFilteredItems().length,
                          itemBuilder: (context, index) => _buildEventCard(_getFilteredItems()[index]),
                        ),
                      ],
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssignTasksPage()),
          );
        },
        backgroundColor: const Color(0xFF9333EA),
        child: const Icon(Icons.group_add),
      ),
    );
  }
}