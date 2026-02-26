import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/task_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/task/empty_tasks_widget.dart';
import '../../widgets/task/shimmer_task_list.dart';
import '../../widgets/task/task_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).loadTasks(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final s = ref.read(taskProvider);
      if (!s.isLoadingMore && s.hasMore) {
        ref.read(taskProvider.notifier).loadTasks();
      }
    }
  }

  Future<void> _refresh() =>
      ref.read(taskProvider.notifier).loadTasks(refresh: true);

  void _onDeleteTask(int taskId) async {
    final ok = await ref.read(taskProvider.notifier).deleteTask(taskId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Task deleted' : 'Failed to delete task'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user =
        authState is AuthAuthenticated ? (authState).user : null;
    final taskState = ref.watch(taskProvider);
    final filteredTasks = ref.watch(filteredTasksProvider);
    final filter = ref.watch(taskFilterProvider);
    final themeMode = ref.watch(themeProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // ── App Bar ───────────────────────────────────────────────────────────
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Hello, ${user?.firstName ?? 'User'} 👋',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${taskState.tasks.length} task${taskState.tasks.length != 1 ? 's' : ''} total',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Dark / light mode toggle
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: () => ref.read(themeProvider.notifier).toggle(),
            tooltip: 'Toggle theme',
          ),
          // User avatar → profile sheet
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: _showProfileSheet,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  user?.initials ?? '?',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // ── Body ──────────────────────────────────────────────────────────────
      body: Column(
        children: [
          // Sticky filter chips
          Container(
            color: colorScheme.surface,
            child: Column(
              children: [
                const Divider(height: 1),
                _FilterChips(
                  selected: filter,
                  onSelected: (f) =>
                      ref.read(taskFilterProvider.notifier).state = f,
                ),
                const Divider(height: 1),
              ],
            ),
          ),
          // Task list
          Expanded(
            child: _buildBody(taskState, filteredTasks, colorScheme),
          ),
        ],
      ),
      // ── FAB ───────────────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/home/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Task'),
      )
          .animate()
          .scale(delay: 300.ms, duration: 400.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildBody(
    TaskState taskState,
    List<TaskModel> tasks,
    ColorScheme colorScheme,
  ) {
    if (taskState.isLoading) {
      return const ShimmerTaskList();
    }

    if (taskState.error != null && tasks.isEmpty) {
      return AppErrorWidget(
        message: taskState.error!,
        onRetry: _refresh,
      );
    }

    if (tasks.isEmpty) {
      return EmptyTasksWidget(
        onCreateTap: () => context.push('/home/create'),
        message: ref.read(taskFilterProvider) == TaskFilter.all
            ? 'No tasks yet.\nTap the button below to add one!'
            : 'No tasks with this status.',
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: tasks.length + (taskState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == tasks.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final task = tasks[index];
          return TaskCard(
            key: ValueKey(task.id),
            task: task,
            index: index,
            onTap: () => context.push('/home/edit', extra: task),
            onDelete: () => _onDeleteTask(task.id),
          );
        },
      ),
    );
  }

  void _showProfileSheet() {
    final authState = ref.read(authProvider);
    final user =
        authState is AuthAuthenticated ? (authState).user : null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    Theme.of(ctx).colorScheme.primaryContainer,
                child: Text(
                  user?.initials ?? '?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(ctx).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user?.fullName ?? 'Unknown',
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                '@${user?.username ?? ''}',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: const Text('Sign Out'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) context.go('/login');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filter chips ───────────────────────────────────────────────────────────────

class _FilterChips extends StatelessWidget {
  final TaskFilter selected;
  final ValueChanged<TaskFilter> onSelected;

  const _FilterChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: TaskFilter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_label(f)),
              selected: isSelected,
              onSelected: (_) => onSelected(f),
              avatar: isSelected ? null : Icon(_icon(f), size: 16),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _label(TaskFilter f) => switch (f) {
        TaskFilter.all => 'All',
        TaskFilter.pending => 'Pending',
        TaskFilter.inProgress => 'In Progress',
        TaskFilter.completed => 'Completed',
      };

  IconData _icon(TaskFilter f) => switch (f) {
        TaskFilter.all => Icons.list_rounded,
        TaskFilter.pending => Icons.hourglass_empty_rounded,
        TaskFilter.inProgress => Icons.autorenew_rounded,
        TaskFilter.completed => Icons.check_circle_outline_rounded,
      };
}
