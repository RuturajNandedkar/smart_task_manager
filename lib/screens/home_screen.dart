import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _TaskFilter { all, completed, high }

class _HomeScreenState extends State<HomeScreen> {
  Stream<List<Task>>? _tasksStream;
  String? _lastUserId;
  _TaskFilter _selectedFilter = _TaskFilter.all;
  late ConfettiController _confettiController;
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _celebrate() {
    _confettiController.play();
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
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final theme = Theme.of(context);

    if (user == null || _tasksStream == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: theme.textTheme.titleMedium,
                  decoration: const InputDecoration(
                    hintText: 'Search tasks...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                )
              : const Text('My Tasks'),
        ),
        centerTitle: false,
        actions: [
          if (!_isSearching) ...[
            IconButton(
              tooltip: 'Search tasks',
              icon: const Icon(Icons.search_rounded),
              onPressed: _toggleSearch,
            ),
            IconButton(
              tooltip: 'Toggle theme',
              icon: context.watch<ThemeProvider>().isDarkMode
                  ? const Icon(Icons.light_mode_outlined)
                  : const Icon(Icons.dark_mode_outlined),
              onPressed: () => context.read<ThemeProvider>().toggleTheme(),
            ),
            IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded),
              onPressed: () => context.read<AuthService>().signOut(),
            ),
          ] else
            IconButton(
              tooltip: 'Close search',
              icon: const Icon(Icons.close_rounded),
              onPressed: _toggleSearch,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildFilterChip('All', _TaskFilter.all),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', _TaskFilter.completed),
                    const SizedBox(width: 8),
                    _buildFilterChip('High Priority', _TaskFilter.high),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Task List
              Expanded(
                child: StreamBuilder<List<Task>>(
                  stream: _tasksStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: theme.colorScheme.error),
                              const SizedBox(height: 16),
                              Text(
                                'Oops! Something went wrong.',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${snapshot.error}',
                                style: TextStyle(color: theme.colorScheme.error),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final tasks = snapshot.data ?? [];
                    final filteredTasks = tasks.where((t) {
                      // Tab filter
                      bool matchesTab = false;
                      switch (_selectedFilter) {
                        case _TaskFilter.completed:
                          matchesTab = t.isCompleted;
                          break;
                        case _TaskFilter.high:
                          matchesTab = t.priority == TaskPriority.high && !t.isCompleted;
                          break;
                        case _TaskFilter.all:
                        default:
                          matchesTab = !t.isCompleted;
                          break;
                      }

                      if (!matchesTab) return false;

                      // Search filter
                      if (_isSearching && _searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        return t.title.toLowerCase().contains(q) ||
                            t.description.toLowerCase().contains(q);
                      }

                      return true;
                    }).toList();

                    if (filteredTasks.isEmpty) {
                      return _buildEmptyState(theme, user.uid,
                          isSearchQuery: _isSearching && _searchQuery.isNotEmpty);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = filteredTasks[index];
                        return _TaskCard(
                          task: task,
                          userId: user.uid,
                          onCompleted: _celebrate,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          // Confetti explosion
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 15,
              colors: const [
                Colors.purple,
                Colors.green,
                Colors.yellow,
                Colors.pink,
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskSheet(context, user.uid),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add),
        label: const Text('New Task', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildFilterChip(String label, _TaskFilter filter) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _selectedFilter = filter);
      },
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String userId, {bool isSearchQuery = false}) {
    IconData icon;
    String title;
    String subtitle;
    Color iconColor = theme.colorScheme.primary.withAlpha(150);
    bool showButton = false;

    if (isSearchQuery) {
      icon = Icons.search_off_rounded;
      title = "No tasks match your search";
      subtitle = "Try a different keyword";
      iconColor = theme.colorScheme.secondary.withAlpha(150);
    } else {
      switch (_selectedFilter) {
        case _TaskFilter.completed:
          icon = Icons.emoji_events_rounded;
          title = "Nothing completed yet";
          subtitle = "Finish a task to see it here";
          break;
        case _TaskFilter.high:
          icon = Icons.flag_rounded;
          title = "No high priority tasks";
          subtitle = "You're all caught up!";
          break;
        case _TaskFilter.all:
        default:
          icon = Icons.task_alt_rounded;
          title = "No tasks yet!";
          subtitle = "Tap + to add your first task";
          iconColor = Colors.deepPurple.withAlpha(100);
          showButton = true;
          break;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: iconColor),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
            if (showButton) ...[
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () => _showAddTaskSheet(context, userId),
                icon: const Icon(Icons.add),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                label: const Text('Add Task'),
              ),
            ],
          ],
        ),
      ),
  }

  void _showAddTaskSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(userId: userId),
    );
  }
}

// ─── Task card ───────────────────────────────────────────────────────────────

class _TaskCard extends StatefulWidget {
  const _TaskCard({required this.task, required this.userId, this.onCompleted});

  final Task task;
  final String userId;
  final VoidCallback? onCompleted;

  @override
  State<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<_TaskCard> {
  double _scale = 1.0;

  Future<void> _animateAndComplete(TaskService taskService, bool isNowCompleted) async {
    if (isNowCompleted) {
      setState(() => _scale = 0.95);
      widget.onCompleted?.call();
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _scale = 1.0);
    }

    try {
      await taskService.toggleCompleted(
        taskId: widget.task.id,
        userId: widget.userId,
        isCompleted: isNowCompleted,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskService = context.watch<TaskService>();
    final task = widget.task;
    final userId = widget.userId;
    final dateStr = DateFormat('MMM d, yyyy').format(task.dueDate);
    final isOverdue = !task.isCompleted && task.dueDate.isBefore(DateTime.now());

    // User-requested priority colors
    final priorityColor = task.priority == TaskPriority.high
        ? const Color(0xFFFF4757)
        : task.priority == TaskPriority.medium
            ? const Color(0xFFFFBA00)
            : const Color(0xFF2ED573);

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Dismissible(
          key: ValueKey(task.id),
          direction: DismissDirection.horizontal,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        onUpdate: (details) {
          if (details.reached && details.previousReached == false) {
            HapticFeedback.mediumImpact();
          }
        },
          onDismissed: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              _animateAndComplete(taskService, true);
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Task completed! ✓'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        taskService.toggleCompleted(
                          taskId: task.id,
                          userId: userId,
                          isCompleted: false,
                        );
                      },
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          } else {
            // Delete
            final taskCopy = task;
            try {
              await taskService.deleteTask(taskId: task.id, userId: userId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).clearSnackBars();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Task deleted'),
                    duration: const Duration(seconds: 3),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () {
                        taskService.addTask(
                          userId: userId,
                          title: taskCopy.title,
                          description: taskCopy.description,
                          dueDate: taskCopy.dueDate,
                          priority: taskCopy.priority,
                        );
                      },
                    ),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            }
          }
        },
        child: Opacity(
          opacity: task.isCompleted ? 0.6 : 1.0,
          child: Card(
            elevation: 2,
            shadowColor: Colors.black.withAlpha(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // Left priority strip
                Container(
                  width: 5,
                  height: 120, // Arbitrary large height to fill the card vertical space
                  color: priorityColor,
                ),
                  Expanded(
                    child: InkWell(
                      onTap: () => _animateAndComplete(taskService, !task.isCompleted),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 16, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                    child: task.isCompleted
                                        ? Icon(Icons.check_circle_rounded, 
                                            key: const ValueKey('completed'), 
                                            color: theme.colorScheme.primary)
                                        : Icon(Icons.radio_button_unchecked, 
                                            key: const ValueKey('incomplete'), 
                                            color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    task.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: Text(
                                  task.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.onSurface.withAlpha(150),
                                  ),
                                ),
                              ),
                            ],
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Due date chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isOverdue
                                      ? const Color(0xFFFF4757).withAlpha(20)
                                      : theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isOverdue
                                          ? Icons.warning_amber_rounded
                                          : Icons.calendar_today_outlined,
                                      size: 14,
                                      color: isOverdue
                                          ? const Color(0xFFFF4757)
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateStr,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isOverdue
                                            ? const Color(0xFFFF4757)
                                            : theme.colorScheme.onSurfaceVariant,
                                        fontWeight: isOverdue
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Priority badge and Edit button
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18),
                                    onPressed: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (context) => _AddTaskSheet(
                                          userId: userId,
                                          task: task,
                                        ),
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    visualDensity: VisualDensity.compact,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: priorityColor.withAlpha(100),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      task.priority.label.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: priorityColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Add task bottom sheet ────────────────────────────────────────────────────

class _AddTaskSheet extends StatefulWidget {
  const _AddTaskSheet({required this.userId, this.task});
  final String userId;
  final Task? task;

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;

  late DateTime _dueDate;
  late TaskPriority _priority;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descController = TextEditingController(text: widget.task?.description ?? '');
    _dueDate = widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _priority = widget.task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow past due for editing
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final taskService = context.read<TaskService>();
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    try {
      if (widget.task == null) {
        // Create mode
        await taskService.addTask(
          userId: widget.userId,
          title: title,
          description: description,
          dueDate: _dueDate,
          priority: _priority,
        );
      } else {
        // Edit mode
        await taskService.updateTask(
          taskId: widget.task!.id,
          userId: widget.userId,
          title: title,
          description: description,
          dueDate: _dueDate,
          priority: _priority,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task updated successfully')),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateDisplay = "Due ${DateFormat('MMM d').format(_dueDate)}";

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Drag handle + Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withAlpha(40),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      widget.task == null ? 'New Task' : 'Edit Task',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),

              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Title field (borderless, 18px)
                          TextFormField(
                            controller: _titleController,
                            autofocus: true,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(
                              hintText: 'What needs to be done?',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                          const SizedBox(height: 8),

                          // Description field (borderless, 14px)
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Add details...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Due date chip
                          Row(
                            children: [
                              ActionChip(
                                avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                                label: Text(dateDisplay),
                                onPressed: _pickDate,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Priority Row
                          Text(
                            'Priority',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurface.withAlpha(150),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: TaskPriority.values.map((p) {
                              final isSelected = _priority == p;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(p.label),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setState(() => _priority = p);
                                  },
                                  showCheckmark: false,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 48),

                          // Submit button (full width, gradient)
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF3B37CC)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6C63FF).withAlpha(80),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : Text(
                                      widget.task == null ? 'Add Task' : 'Save Changes',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
