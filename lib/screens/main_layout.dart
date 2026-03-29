import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 1;

  final List<Widget> _pages = const [
    DashboardScreen(),
    HomeScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(240),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(50),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBar(
                height: 64,
                elevation: 0,
                backgroundColor: Colors.transparent,
                labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard_rounded),
                    label: 'Stats',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.task_alt_outlined),
                    selectedIcon: Icon(Icons.task_alt_rounded),
                    label: 'Tasks',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_month_outlined),
                    selectedIcon: Icon(Icons.calendar_month_rounded),
                    label: 'Calendar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
