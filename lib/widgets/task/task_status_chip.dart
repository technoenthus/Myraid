import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/task_model.dart';

class TaskStatusChip extends StatelessWidget {
  final TaskStatus status;
  final bool small;

  const TaskStatusChip({super.key, required this.status, this.small = false});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      TaskStatus.pending => (AppTheme.pendingColor, Icons.hourglass_empty_rounded),
      TaskStatus.inProgress => (AppTheme.inProgressColor, Icons.autorenew_rounded),
      TaskStatus.completed => (AppTheme.completedColor, Icons.check_circle_rounded),
    };

    final fontSize = small ? 11.0 : 12.0;
    final iconSize = small ? 12.0 : 14.0;
    final padding = small
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 10, vertical: 4);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
