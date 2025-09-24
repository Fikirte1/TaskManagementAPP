import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:task_management/model/assignment_models.dart';
import 'package:task_management/service/assignment_service.dart';

class TrackProgressPage extends StatefulWidget {
  const TrackProgressPage({super.key});

  @override
  State<TrackProgressPage> createState() => _TrackProgressPageState();
}

class _TrackProgressPageState extends State<TrackProgressPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Project> _projects = [];
  List<TeamMember> _teamMembers = [];
  List<ProgressData> _progressData = [];
  String _selectedTimeRange = 'Weekly';
  String _selectedProject = 'All Projects';
  bool _isLoading = true;
  String? _errorMessage;

  StreamSubscription<QuerySnapshot>? _projectsSubscription;
  StreamSubscription<QuerySnapshot>? _teamMembersSubscription;
  StreamSubscription<QuerySnapshot>? _progressDataSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    _teamMembersSubscription?.cancel();
    _progressDataSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    _loadProjects();
    _loadTeamMembers();
    _loadProgressData();
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

  void _loadProgressData() {
    if (_projects.isEmpty && _selectedProject != 'All Projects') {
      setState(() {
        _isLoading = false;
        _errorMessage = "No projects available to filter progress data";
      });
      return;
    }

    _progressDataSubscription?.cancel();
    _progressDataSubscription = AssignmentService.getProgressData(
      projectId: _selectedProject == 'All Projects'
          ? null
          : _projects.firstWhere((p) => p.name == _selectedProject, orElse: () => _projects.first).id,
      timeRange: _selectedTimeRange,
    ).listen(
      (QuerySnapshot snapshot) {
        if (!mounted) return;
        final progressData = snapshot.docs.map((doc) {
          try {
            return ProgressData.fromFirestore(doc);
          } catch (e) {
            debugPrint("Error parsing progress data: $e");
            return null;
          }
        }).whereType<ProgressData>().toList();
        setState(() {
          _progressData = progressData;
          _checkIfDataLoaded();
        });
      },
      onError: (error) {
        debugPrint("Error loading progress data: $error");
        if (mounted) {
          setState(() {
            _errorMessage = "Failed to load progress data";
            _checkIfDataLoaded();
          });
        }
      },
    );
  }

  void _checkIfDataLoaded() {
    if (_projects.isNotEmpty || _teamMembers.isNotEmpty || _progressData.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get _overallProgress {
    if (_projects.isEmpty) return 0.0;
    final totalProgress = _projects.fold(0.0, (sum, project) => sum + project.progress);
    return totalProgress / _projects.length;
  }

  int get _totalTasks {
    return _projects.fold(0, (sum, project) => sum + project.totalTasks);
  }

  int get _completedTasks {
    return _projects.fold(0, (sum, project) => sum + project.completedTasks);
  }

  int get _remainingDays {
    if (_projects.isEmpty) return 0;
    final latestEndDate = _projects.map((p) => p.endDate ?? DateTime.now()).reduce((a, b) => a.isAfter(b) ? a : b);
    return latestEndDate.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Progress Tracking',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF6B7280)),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : Column(
                  children: [
                    _buildOverviewCards(),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF2563EB),
                        unselectedLabelColor: const Color(0xFF6B7280),
                        indicatorColor: const Color(0xFF2563EB),
                        tabs: const [
                          Tab(text: 'Projects'),
                          Tab(text: 'Team'),
                          Tab(text: 'Analytics'),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildProjectsTab(),
                          _buildTeamTab(),
                          _buildAnalyticsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOverviewCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: _buildOverviewCard(
              'Overall Progress',
              '${(_overallProgress * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
              const Color(0xFF10B981),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Tasks Completed',
              '$_completedTasks/$_totalTasks',
              Icons.task_alt,
              const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildOverviewCard(
              'Days Remaining',
              _remainingDays < 0 ? 'Overdue' : '$_remainingDays days',
              Icons.calendar_today,
              const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _projects.map((project) => _buildProjectCard(project)).toList(),
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final daysRemaining = (project.endDate ?? DateTime.now()).difference(DateTime.now()).inDays;
    final isOverdue = daysRemaining < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showUpdateProjectDialog(project),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${(project.progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: project.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: project.progress,
                backgroundColor: Colors.grey[200],
                color: project.color,
                borderRadius: BorderRadius.circular(10),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildProjectDetail('Tasks', '${project.completedTasks}/${project.totalTasks}'),
                  _buildProjectDetail('Manager', project.manager),
                  _buildProjectDetail('Deadline', isOverdue ? 'Overdue' : '$daysRemaining days'),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF6B7280)),
                    onPressed: () => _showUpdateProjectDialog(project),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTeamTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTeamProductivityChart(),
          const SizedBox(height: 20),
          ..._teamMembers.map((member) => _buildTeamMemberCard(member)),
        ],
      ),
    );
  }

  Widget _buildTeamProductivityChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Team Productivity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                primaryYAxis: const NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  interval: 20,
                  title: AxisTitle(text: 'Productivity (%)'),
                ),
                series: <CartesianSeries>[
                  BarSeries<TeamMember, String>(
                    dataSource: _teamMembers,
                    xValueMapper: (TeamMember member, _) => member.name.isEmpty ? 'N/A' : member.name.split(' ')[0],
                    yValueMapper: (TeamMember member, _) => (member.productivity * 100).toDouble(),
                    color: const Color(0xFF6366F1),
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamMemberCard(TeamMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              member.avatar.isEmpty ? 'N/A' : member.avatar,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(member.role),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${(member.productivity * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
            Text(
              'Productivity',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildProgressTrendChart(),
          const SizedBox(height: 20),
          _buildTaskDistributionChart(),
          const SizedBox(height: 20),
          _buildPerformanceMetrics(),
        ],
      ),
    );
  }

  Widget _buildProgressTrendChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCartesianChart(
                primaryXAxis: const CategoryAxis(),
                primaryYAxis: const NumericAxis(
                  minimum: 0,
                  maximum: 100,
                  interval: 20,
                  title: AxisTitle(text: 'Progress (%)'),
                ),
                series: <CartesianSeries>[
                  LineSeries<ProgressData, String>(
                    dataSource: _progressData,
                    xValueMapper: (ProgressData data, _) => data.day.isEmpty ? 'N/A' : data.day,
                    yValueMapper: (ProgressData data, _) => (data.progress * 100).toDouble(),
                    color: const Color(0xFF10B981),
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDistributionChart() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Distribution',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<Project, String>(
                    dataSource: _projects,
                    xValueMapper: (Project project, _) => project.name,
                    yValueMapper: (Project project, _) => project.totalTasks.toDouble(),
                    pointColorMapper: (Project project, _) => project.color,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
                legend: const Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
              ),
            ),
            const SizedBox(height: 16),
            _buildProjectLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _projects.map((project) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: project.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              project.name,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPerformanceMetrics() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Metrics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard('Avg. Completion Rate',
                    '${(_overallProgress * 100).toStringAsFixed(0)}%', Icons.check_circle, Colors.green),
                _buildMetricCard('On-Time Delivery',
                    _totalTasks > 0 ? '${(_completedTasks / _totalTasks * 100).toStringAsFixed(0)}%' : '0%', Icons.schedule, Colors.orange),
                _buildMetricCard('Team Utilization',
                    _teamMembers.isNotEmpty ? '${(_teamMembers.fold(0.0, (sum, m) => sum + m.productivity) / _teamMembers.length * 100).toStringAsFixed(0)}%' : '0%', Icons.people, Colors.blue),
                _buildMetricCard('Quality Score', '88%', Icons.star, Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('Time Range', _selectedTimeRange, ['Weekly', 'Monthly', 'Quarterly']),
            const SizedBox(height: 16),
            _buildFilterOption('Project', _selectedProject, ['All Projects', ..._projects.map((p) => p.name)]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadProgressData();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String title, String currentValue, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: currentValue,
          items: options.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              if (title == 'Time Range') {
                _selectedTimeRange = value!;
              } else {
                _selectedProject = value!;
              }
            });
          },
        ),
      ],
    );
  }

  void _showUpdateProjectDialog(Project project) {
    final nameController = TextEditingController(text: project.name);
    final descriptionController = TextEditingController(text: project.description);
    final managerController = TextEditingController(text: project.manager);
    DateTime? selectedEndDate = project.endDate;
    Color selectedColor = project.color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: managerController,
                decoration: const InputDecoration(labelText: 'Manager'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  selectedEndDate == null
                      ? 'Select End Date'
                      : 'End Date: ${DateFormat('yyyy-MM-dd').format(selectedEndDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedEndDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedEndDate = pickedDate;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Select Color'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Pick a Color'),
                      content: SingleChildScrollView(
                        child: BlockPicker(
                          pickerColor: selectedColor,
                          onColorChanged: (color) {
                            selectedColor = color;
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project name cannot be empty'), backgroundColor: Colors.red),
                );
                return;
              }
              try {
                final updatedProject = Project(
                  id: project.id,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  startDate: project.startDate,
                  endDate: selectedEndDate,
                  teamMembers: project.teamMembers,
                  createdAt: project.createdAt,
                  progress: project.progress,
                  totalTasks: project.totalTasks,
                  completedTasks: project.completedTasks,
                  color: selectedColor,
                  manager: managerController.text.trim(),
                );
                await AssignmentService.updateProject(project.id, updatedProject.toMap());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Project updated successfully'), backgroundColor: Colors.green),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update project: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}