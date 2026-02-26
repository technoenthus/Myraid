import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class EmptyTasksWidget extends StatelessWidget {
  final VoidCallback onCreateTap;
  final String message;

  const EmptyTasksWidget({
    super.key,
    required this.onCreateTap,
    this.message = 'No tasks yet.\nCreate your first task!',
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rounded,
                size: 60,
                color: colorScheme.primary,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(
                  end: 1.05,
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
            const SizedBox(height: 24),
            Text(
              'All Clear!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onCreateTap,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Task'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(180, 48),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.15, end: 0, duration: 500.ms),
      ),
    );
  }
}
