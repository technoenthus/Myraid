import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/task_model.dart';
import '../data/repositories/task_repository.dart';
import '../core/constants/api_constants.dart';
import 'auth_provider.dart';

// ── Infrastructure ─────────────────────────────────────────────────────────────

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    ref.read(apiServiceProvider),
    ref.read(storageServiceProvider),
  );
});

// ── Filter ─────────────────────────────────────────────────────────────────────

enum TaskFilter { all, pending, inProgress, completed }

final taskFilterProvider =
    StateProvider<TaskFilter>((_) => TaskFilter.all);

// ── Task state ─────────────────────────────────────────────────────────────────

class TaskState {
  final List<TaskModel> tasks;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool hasMore;
  final int page;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.hasMore = true,
    this.page = 0,
  });

  TaskState copyWith({
    List<TaskModel>? tasks,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? hasMore,
    int? page,
    bool clearError = false,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

// ── Notifier ────────────────────────────────────────────────────────────────────

class TaskNotifier extends StateNotifier<TaskState> {
  final TaskRepository _repo;
  final int _userId;

  TaskNotifier(this._repo, this._userId) : super(const TaskState());

  Future<void> loadTasks({bool refresh = false}) async {
    if (!refresh && (state.isLoading || state.isLoadingMore)) return;
    if (!refresh && !state.hasMore) return;

    if (refresh || state.tasks.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true, page: 0);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    final skip = refresh ? 0 : state.page * ApiConstants.pageLimit;

    try {
      final fetched = await _repo.getTasks(
        userId: _userId,
        skip: skip,
        limit: ApiConstants.pageLimit,
      );

      final merged = refresh ? fetched : [...state.tasks, ...fetched];
      state = state.copyWith(
        tasks: merged,
        isLoading: false,
        isLoadingMore: false,
        hasMore: fetched.length >= ApiConstants.pageLimit,
        page: refresh ? 1 : state.page + 1,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> createTask({
    required String title,
    required String description,
    required TaskStatus status,
    DateTime? dueDate,
  }) async {
    try {
      final task = await _repo.createTask(
        title: title,
        description: description,
        status: status,
        dueDate: dueDate,
        userId: _userId,
      );
      state = state.copyWith(tasks: [task, ...state.tasks]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTask(TaskModel task) async {
    try {
      final updated = await _repo.updateTask(task);
      state = state.copyWith(
        tasks: [for (final t in state.tasks) t.id == task.id ? updated : t],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      await _repo.deleteTask(taskId);
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != taskId).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final taskProvider =
    StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final authState = ref.watch(authProvider);
  final userId =
      authState is AuthAuthenticated ? authState.user.id : 0;
  return TaskNotifier(ref.read(taskRepositoryProvider), userId);
});

// ── Derived: filtered tasks ────────────────────────────────────────────────────

final filteredTasksProvider = Provider<List<TaskModel>>((ref) {
  final tasks = ref.watch(taskProvider).tasks;
  final filter = ref.watch(taskFilterProvider);
  switch (filter) {
    case TaskFilter.all:
      return tasks;
    case TaskFilter.pending:
      return tasks.where((t) => t.status == TaskStatus.pending).toList();
    case TaskFilter.inProgress:
      return tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    case TaskFilter.completed:
      return tasks.where((t) => t.status == TaskStatus.completed).toList();
  }
});
