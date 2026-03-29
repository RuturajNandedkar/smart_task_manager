import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  Stream<List<Task>>? _tasksStream;
  String? _lastUserId;

  late AnimationController _animController;
  late List<Animation<double>> _staggeredAnims;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _staggeredAnims = List.generate(4, (i) {
      final start = i * 0.1;
      return CurvedAnimation(
        parent: _animController,
        curve: Interval(start, (start + 0.5).clamp(0.0, 1.0), curve: Curves.easeOut),
      );
    });

    _animController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<User?>();
    if (user != null && user.uid != _lastUserId) {
      _lastUserId = user.uid;
      _tasksStream = context.read<TaskService>().streamTasks(user.uid);
    } else if (user == null) {
      _lastUserId = null;
      _tasksStream = null;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_tasksStream == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statistics')),
        body: _buildShimmerLoading(),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        elevation: 0,
      ),
      body: StreamBuilder<List<Task>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLoading();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          final totalTasks = tasks.length;
          final completedTasks = tasks.where((t) => t.isCompleted).length;
          final pendingTasks = totalTasks - completedTasks;
          final highPriority = tasks.where((t) => !t.isCompleted && t.priority == TaskPriority.high).length;

          final mediumPriority = tasks.where((t) => !t.isCompleted && t.priority == TaskPriority.medium).length;
          final lowPriority = tasks.where((t) => !t.isCompleted && t.priority == TaskPriority.low).length;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 2x2 Grid of Stat Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Total Tasks',
                      value: '$totalTasks',
                      icon: Icons.assignment_rounded,
                      gradient: const [Color(0xFF6C63FF), Color(0xFF3B37CC)],
                      animation: _staggeredAnims[0],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'Completed',
                      value: '$completedTasks',
                      icon: Icons.task_alt_rounded,
                      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                      animation: _staggeredAnims[1],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'Pending',
                      value: '$pendingTasks',
                      icon: Icons.pending_actions_rounded,
                      gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                      animation: _staggeredAnims[2],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'High Priority',
                      value: '$highPriority',
                      icon: Icons.priority_high_rounded,
                      gradient: const [Color(0xFFFC466B), Color(0xFF3F5EFB)],
                      animation: _staggeredAnims[3],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Text(
                'Other Priorities',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildPriorityRow(context, 'Medium', mediumPriority, TaskPriority.medium.color),
              const Divider(height: 24),
              _buildPriorityRow(context, 'Low', lowPriority, TaskPriority.low.color),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
    required Animation<double> animation,
  }) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withAlpha(80),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withAlpha(216), // ~0.85 opacity
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: _buildShimmerBox()),
            const SizedBox(width: 16),
            Expanded(child: _buildShimmerBox()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildShimmerBox()),
            const SizedBox(width: 16),
            Expanded(child: _buildShimmerBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildPriorityRow(BuildContext context, String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          Text(
            '$count',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
