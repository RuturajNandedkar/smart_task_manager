import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../services/task_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Stream<List<Task>>? _tasksStream;
  String? _lastUserId;

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
  Widget build(BuildContext context) {
    if (_tasksStream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: StreamBuilder<List<Task>>(
        stream: _tasksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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

          double completionRate = totalTasks == 0 ? 0 : completedTasks / totalTasks;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatCard(
                context,
                title: 'Completion Rate',
                value: '${(completionRate * 100).toStringAsFixed(1)}%',
                icon: Icons.pie_chart_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(context, title: 'Pending', value: '$pendingTasks', icon: Icons.pending_actions_rounded, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(context, title: 'Completed', value: '$completedTasks', icon: Icons.task_alt_rounded, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Pending by Priority', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildPriorityRow(context, 'High', highPriority, TaskPriority.high.color),
              const SizedBox(height: 8),
              _buildPriorityRow(context, 'Medium', mediumPriority, TaskPriority.medium.color),
              const SizedBox(height: 8),
              _buildPriorityRow(context, 'Low', lowPriority, TaskPriority.low.color),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required String value, required IconData icon, required Color color}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityRow(BuildContext context, String label, int count, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
