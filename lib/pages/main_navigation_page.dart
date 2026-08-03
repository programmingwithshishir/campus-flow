import 'package:flutter/material.dart';

import '../features/attendance/pages/attendance_tracker_page.dart';
import '../features/tasks/pages/task_manager_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    TaskManagerPage(),
    AttendanceTrackerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final navBgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final navBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBgColor,
          border: Border(
            top: BorderSide(color: navBorderColor, width: 1),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: navBgColor,
          indicatorColor: isDark ? const Color(0xFF2563EB).withValues(alpha: 0.3) : const Color(0xFF2563EB).withValues(alpha: 0.15),
          elevation: 0,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.check_circle_outline_rounded),
              selectedIcon: Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)),
              label: 'To Do',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school_rounded, color: Color(0xFF2563EB)),
              label: 'Attendance',
            ),
          ],
        ),
      ),
    );
  }
}
