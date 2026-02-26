import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/utils/validators.dart';
import '../../data/models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/task/task_status_chip.dart';

class TaskFormScreen extends ConsumerStatefulWidget {
  final TaskModel? task; // null = create, non-null = edit

  const TaskFormScreen({super.key, this.task});

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dueDateCtrl = TextEditingController();

  TaskStatus _status = TaskStatus.pending;
  DateTime? _dueDate;
  bool _isLoading = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final t = widget.task!;
      _titleCtrl.text = t.title;
      _descCtrl.text = t.description;
      _status = t.status;
      _dueDate = t.dueDate;
      if (t.dueDate != null) {
        _dueDateCtrl.text = DateFormat('MMM d, yyyy').format(t.dueDate!);
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateCtrl.text = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  void _clearDate() {
    setState(() {
      _dueDate = null;
      _dueDateCtrl.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    bool success;
    if (isEditing) {
      final updated = widget.task!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        status: _status,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
      );
      success = await ref.read(taskProvider.notifier).updateTask(updated);
    } else {
      success = await ref.read(taskProvider.notifier).createTask(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            status: _status,
            dueDate: _dueDate,
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(isEditing ? 'Task updated!' : 'Task created!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Something went wrong. Please try again.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              _sectionLabel('Task Title *'),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Title',
                hint: 'What needs to be done?',
                controller: _titleCtrl,
                prefixIcon: Icons.title_rounded,
                validator: Validators.validateTitle,
                textInputAction: TextInputAction.next,
              )
                  .animate()
                  .fadeIn(delay: 50.ms)
                  .slideX(begin: -0.04, end: 0),

              const SizedBox(height: 20),

              // Description
              _sectionLabel('Description'),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Description',
                hint: 'Add more details (optional)',
                controller: _descCtrl,
                prefixIcon: Icons.notes_rounded,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              )
                  .animate()
                  .fadeIn(delay: 100.ms)
                  .slideX(begin: -0.04, end: 0),

              const SizedBox(height: 20),

              // Status
              _sectionLabel('Status'),
              const SizedBox(height: 10),
              _StatusSelector(
                selected: _status,
                onChanged: (s) => setState(() => _status = s),
              )
                  .animate()
                  .fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // Due Date
              _sectionLabel('Due Date'),
              const SizedBox(height: 8),
              CustomTextField(
                label: 'Due Date',
                hint: 'Select a due date (optional)',
                controller: _dueDateCtrl,
                prefixIcon: Icons.calendar_today_rounded,
                readOnly: true,
                onTap: _pickDate,
                suffixWidget: _dueDate != null
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: _clearDate,
                      )
                    : const Icon(Icons.arrow_drop_down_rounded),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .slideX(begin: -0.04, end: 0),

              const SizedBox(height: 36),

              CustomButton(
                label: isEditing ? 'Update Task' : 'Create Task',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: isEditing
                    ? Icons.save_rounded
                    : Icons.add_task_rounded,
              )
                  .animate()
                  .fadeIn(delay: 250.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }

  void _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text(
            'Delete "${widget.task!.title}"? This action cannot be undone.'),
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

    if (confirmed == true && mounted) {
      await ref.read(taskProvider.notifier).deleteTask(widget.task!.id);
      if (mounted) context.pop();
    }
  }
}

// ── Status selector ────────────────────────────────────────────────────────────

class _StatusSelector extends StatelessWidget {
  final TaskStatus selected;
  final ValueChanged<TaskStatus> onChanged;

  const _StatusSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskStatus.values.map((s) {
        final isSelected = s == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(s),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: TaskStatusChip(status: s, small: true),
            ),
          ),
        );
      }).toList(),
    );
  }
}
