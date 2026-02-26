import '../models/task_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../core/constants/api_constants.dart';

class TaskRepository {
  final ApiService _api;
  final StorageService _storage;

  // IDs >= this are local-only (not yet synced / demo API can't persist)
  static const int _localIdBase = 900000;
  int _localIdCounter = _localIdBase;

  TaskRepository(this._api, this._storage);

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<List<TaskModel>> getTasks({
    required int userId,
    int skip = 0,
    int limit = ApiConstants.pageLimit,
  }) async {
    try {
      final response = await _api.get(
        ApiConstants.userTodos(userId),
        queryParameters: {'limit': limit, 'skip': skip},
      );

      final data = response as Map<String, dynamic>;
      final todos = data['todos'] as List<dynamic>;

      // Merge API todos with locally cached data (description, dueDate, etc.)
      final cachedMap = {
        for (final t in _storage.getCachedTasks()) t.id: t
      };

      final apiTasks = todos.map((raw) {
        final json = raw as Map<String, dynamic>;
        final id = json['id'] as int;
        // If we have richer local data, prefer it
        return cachedMap[id] ?? TaskModel.fromApiJson(json);
      }).toList();

      // On first page, prepend local-only tasks (created offline)
      if (skip == 0) {
        final apiIds = todos.map((r) => (r as Map)['id'] as int).toSet();
        final localOnly = _storage
            .getCachedTasks()
            .where((t) => !apiIds.contains(t.id) && t.userId == userId)
            .toList();
        return [...localOnly, ...apiTasks];
      }
      return apiTasks;
    } catch (_) {
      // Fallback to cache
      final cached = _storage.getCachedTasks();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  // ── Create ────────────────────────────────────────────────────────────────

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required TaskStatus status,
    DateTime? dueDate,
    required int userId,
  }) async {
    int id;
    try {
      final res = await _api.post(
        ApiConstants.addTodo,
        data: {'todo': title, 'completed': status == TaskStatus.completed, 'userId': userId},
      );
      id = res['id'] as int;
    } catch (_) {
      // Use a local ID if API call fails
      id = _localIdCounter++;
    }

    final task = TaskModel(
      id: id,
      title: title,
      description: description,
      status: status,
      dueDate: dueDate,
      userId: userId,
      createdAt: DateTime.now(),
    );
    await _upsertCache(task);
    return task;
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<TaskModel> updateTask(TaskModel task) async {
    if (task.id < _localIdBase) {
      try {
        await _api.put(
          ApiConstants.todoById(task.id),
          data: {'todo': task.title, 'completed': task.status == TaskStatus.completed},
        );
      } catch (_) {
        // local-first: continue even if network fails
      }
    }
    await _upsertCache(task);
    return task;
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteTask(int taskId) async {
    if (taskId < _localIdBase) {
      try {
        await _api.delete(ApiConstants.todoById(taskId));
      } catch (_) {
        // local-first
      }
    }
    await _removeFromCache(taskId);
  }

  // ── Cache helpers ─────────────────────────────────────────────────────────

  Future<void> _upsertCache(TaskModel task) async {
    final tasks = _storage.getCachedTasks();
    final idx = tasks.indexWhere((t) => t.id == task.id);
    if (idx >= 0) {
      tasks[idx] = task;
    } else {
      tasks.insert(0, task);
    }
    await _storage.saveTasks(tasks);
  }

  Future<void> _removeFromCache(int id) async {
    final tasks = _storage.getCachedTasks()..removeWhere((t) => t.id == id);
    await _storage.saveTasks(tasks);
  }
}
