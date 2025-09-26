import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:task_management/screen/AllTasksPage.dart';
import 'package:task_management/screen/AssignTasksPage.dart';
import 'package:task_management/screen/IssuesPage.dart';
import 'package:task_management/screen/Login.dart';
import 'package:task_management/screen/NotificationsPage.dart';
import 'package:task_management/screen/ProfilePage.dart';
import 'package:task_management/screen/ProjectsPage.dart';
import 'package:task_management/screen/SchedulePage.dart';
import 'package:task_management/screen/TrackProgress.dart';
import 'package:task_management/screen/team_management_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const DashboardCard({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 140),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [bgColor, _darkenColor(bgColor, 0.1)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: bgColor.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor.withOpacity(0.2), iconColor.withOpacity(0.1)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    description,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.arrow_forward, color: iconColor, size: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _darkenColor(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - factor).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

enum MenuAction { profile, settings, logout }

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  int _unreadNotifications = 0;
  int _pendingTasks = 0;
  int _completedTasks = 0;
  int _overdueTasks = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _tasksSubscription;

  final user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadTaskCounts();
  }

  @override
  void dispose() {
    _tasksSubscription?.cancel();
    super.dispose();
  }

 void _loadTaskCounts() {
  if (user != null) {
    _tasksSubscription = FirebaseFirestore.instance
        .collection('tasks')
        .where('assignedUserId', isEqualTo: user!.uid)
        .snapshots()
        .listen(
      (snapshot) {
        int unreadCount = 0;
        int pendingCount = 0;
        int completedCount = 0;
        int overdueCount = 0;
        final now = DateTime.now();

        for (var doc in snapshot.docs) {
          final data = doc.data();
          
          // Count unread notifications
          if (data['isRead'] == false) {
            unreadCount++;
          }
          
          // Count by status
          switch (data['status']) {
            case 'pending':
              pendingCount++;
              break;
            case 'completed':
              completedCount++;
              break;
            case 'in progress':
              pendingCount++; // or create separate counter if needed
              break;
          }
          
          // Count overdue tasks
          if (data['dueDate'] != null && 
              data['status'] != 'completed' &&
              (data['dueDate'] as Timestamp).toDate().isBefore(now)) {
            overdueCount++;
          }
        }

        if (mounted) {
          setState(() {
            _unreadNotifications = unreadCount;
            _pendingTasks = pendingCount;
            _completedTasks = completedCount;
            _overdueTasks = overdueCount;
          });
        }
      },
      onError: (error) {
        print('Error loading tasks: $error');
      },
    );
  }
}
void _showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Settings'),
      content: const Text('Settings page coming soon!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late final List<Widget> _pages = [
    _buildHomePage(),
    const ProjectsPage(),
    const TeamManagementPage(),
    const SchedulePage(),
    const IssuesPage(),
  ];

  Widget _buildHomePage() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard Overview",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Pending",
                      _pendingTasks.toString(),
                      Icons.schedule,
                      const Color(0xFFFFF3CD),
                      const Color(0xFF856404),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Completed",
                      _completedTasks.toString(),
                      Icons.check_circle,
                      const Color(0xFFD4EDDA),
                      const Color(0xFF155724),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      "Overdue",
                      _overdueTasks.toString(),
                      Icons.warning,
                      const Color(0xFFF8D7DA),
                      const Color(0xFF721C24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildNotificationsCard(),
            const SizedBox(height: 32),
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              children: [
                DashboardCard(
                  title: "All Tasks",
                  description: "View and manage all your tasks",
                  icon: Icons.task_alt,
                  iconColor: const Color(0xFF2563EB),
                  bgColor: const Color(0xFFEFF6FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllTasksPage()),
                    );
                  },
                ),
                DashboardCard(
                  title: "Track Progress",
                  description: "Monitor task and project status",
                  icon: Icons.analytics_outlined,
                  iconColor: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFF0FDF4),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TrackProgressPage()),
                    );
                  },
                ),
                DashboardCard(
                  title: "Assign Tasks",
                  description: "Delegate work to your team",
                  icon: Icons.group_add,
                  iconColor: const Color(0xFF9333EA),
                  bgColor: const Color(0xFFF3E8FF),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AssignTasksPage()),
                    );
                  },
                ),
                DashboardCard(
                  title: "Issues",
                  description: "Manage and resolve issues",
                  icon: Icons.warning_amber_rounded,
                  iconColor: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEF2F2),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const IssuesPage()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsPage()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _unreadNotifications > 0
                            ? '$_unreadNotifications new notifications'
                            : 'No new notifications',
                        style: TextStyle(
                          color: _unreadNotifications > 0
                              ? const Color(0xFFEF4444)
                              : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 16,
                    ),
                    if (_unreadNotifications > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$_unreadNotifications',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: textColor),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please log in to continue'),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signInAnonymously();
                  setState(() {});
                },
                child: const Text('Sign In Anonymously'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.work, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Task Management",
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      size: 24, color: Color(0xFF6B7280)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsPage()),
                  );
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_unreadNotifications > 99 ? '99+' : _unreadNotifications}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        PopupMenuButton<MenuAction>(
  onSelected: (MenuAction result) {
    switch (result) {
      case MenuAction.profile:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
      case MenuAction.settings:
        // You can add settings navigation here too
        _showSettingsDialog(context);
        break;
      case MenuAction.logout:
        _logout();
        break;
    }
  },
  
            itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuAction>>[
              PopupMenuItem<MenuAction>(
                value: MenuAction.profile,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Profile'),
                ),
              ),
              PopupMenuItem<MenuAction>(
                value: MenuAction.settings,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.settings, color: Color(0xFF16A34A)),
                  ),
                  title: const Text('Settings'),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<MenuAction>(
                value: MenuAction.logout,
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(Icons.dashboard, 'Home', 0),
              _buildBottomNavItem(Icons.folder_special, 'Projects', 1),
              _buildBottomNavItem(Icons.people, 'Team', 2),
              _buildBottomNavItem(Icons.calendar_today, 'Schedule', 3),
              _buildBottomNavItem(Icons.warning, 'Issues', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(IconData icon, String label, int index) {
    bool isActive = _selectedIndex == index;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}