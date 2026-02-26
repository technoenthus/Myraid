import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';
import 'task_status_chip.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int index;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onDelete,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(
              'Delete',
              style: theme.textTheme.labelSmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.status == TaskStatus.completed
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TaskStatusChip(status: task.status, small: true),
                  ],
                ),
                // Description
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Footer row
                Row(
                  children: [
                    if (task.dueDate != null) ...[
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 14,
                        color: task.isOverdue
                            ? AppTheme.overdueColor
                            : colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy').format(task.dueDate!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: task.isOverdue
                              ? AppTheme.overdueColor
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: task.isOverdue ? FontWeight.w600 : null,
                        ),
                      ),
                      if (task.isOverdue) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.overdueColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Overdue',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      )
          .animate(delay: (index * 60).ms)
          .fadeIn(duration: 300.ms)
          .slideX(begin: 0.05, end: 0, duration: 300.ms),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
