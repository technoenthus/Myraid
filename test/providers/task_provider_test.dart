import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:myraid_tasks/core/utils/validators.dart';
import 'package:myraid_tasks/data/models/task_model.dart';
import 'package:myraid_tasks/data/repositories/task_repository.dart';
import 'package:myraid_tasks/providers/task_provider.dart';

@GenerateMocks([TaskRepository])
import 'task_provider_test.mocks.dart';

void main() {
  late MockTaskRepository mockRepo;

  const testUserId = 5;

  final sampleTask = TaskModel(
    id: 1,
    title: 'Buy groceries',
    description: 'Milk, eggs, bread',
    status: TaskStatus.pending,
    userId: testUserId,
    createdAt: DateTime(2025, 1, 1),
  );

  setUp(() {
    mockRepo = MockTaskRepository();
  });

  // ── TaskNotifier ──────────────────────────────────────────────────────────

  group('TaskNotifier', () {
    test('initial state has empty task list', () {
      final notifier = TaskNotifier(mockRepo, testUserId);
      expect(notifier.state.tasks, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('loadTasks populates tasks on success', () async {
      when(mockRepo.getTasks(userId: testUserId, skip: 0, limit: 10))
          .thenAnswer((_) async => [sampleTask]);

      final notifier = TaskNotifier(mockRepo, testUserId);
      await notifier.loadTasks(refresh: true);

      expect(notifier.state.tasks, hasLength(1));
      expect(notifier.state.tasks.first.title, 'Buy groceries');
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNull);
    });

    test('loadTasks sets error state on failure', () async {
      when(mockRepo.getTasks(userId: testUserId, skip: 0, limit: 10))
          .thenThrow(Exception('Network error'));

      final notifier = TaskNotifier(mockRepo, testUserId);
      await notifier.loadTasks(refresh: true);

      expect(notifier.state.tasks, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.error, isNotNull);
    });

    test('createTask prepends new task to list', () async {
      final newTask = sampleTask.copyWith(title: 'New Task');
      when(mockRepo.createTask(
        title: 'New Task',
        description: 'Desc',
        status: TaskStatus.pending,
        dueDate: null,
        userId: testUserId,
      )).thenAnswer((_) async => newTask);

      final notifier = TaskNotifier(mockRepo, testUserId);
      final success = await notifier.createTask(
        title: 'New Task',
        description: 'Desc',
        status: TaskStatus.pending,
      );

      expect(success, isTrue);
      expect(notifier.state.tasks, hasLength(1));
      expect(notifier.state.tasks.first.title, 'New Task');
    });

    test('updateTask replaces matching task', () async {
      final updated = sampleTask.copyWith(status: TaskStatus.completed);
      when(mockRepo.updateTask(any)).thenAnswer((_) async => updated);

      final notifier = TaskNotifier(mockRepo, testUserId);
      notifier.state = notifier.state.copyWith(tasks: [sampleTask]);

      final success = await notifier.updateTask(updated);

      expect(success, isTrue);
      expect(notifier.state.tasks.first.status, TaskStatus.completed);
    });

    test('deleteTask removes task by id', () async {
      when(mockRepo.deleteTask(sampleTask.id)).thenAnswer((_) async {});

      final notifier = TaskNotifier(mockRepo, testUserId);
      notifier.state = notifier.state.copyWith(tasks: [sampleTask]);

      final success = await notifier.deleteTask(sampleTask.id);

      expect(success, isTrue);
      expect(notifier.state.tasks, isEmpty);
    });
  });

  // ── TaskModel ─────────────────────────────────────────────────────────────

  group('TaskModel', () {
    test('isOverdue is true for past due pending task', () {
      final task = TaskModel(
        id: 2,
        title: 'Overdue',
        description: '',
        status: TaskStatus.pending,
        dueDate: DateTime(2000, 1, 1),
        userId: 1,
        createdAt: DateTime(2000, 1, 1),
      );
      expect(task.isOverdue, isTrue);
    });

    test('isOverdue is false for completed task even if due date passed', () {
      final task = TaskModel(
        id: 3,
        title: 'Done',
        description: '',
        status: TaskStatus.completed,
        dueDate: DateTime(2000, 1, 1),
        userId: 1,
        createdAt: DateTime(2000, 1, 1),
      );
      expect(task.isOverdue, isFalse);
    });

    test('isOverdue is false when no due date', () {
      expect(sampleTask.isOverdue, isFalse);
    });

    test('toLocalJson / fromLocalJson round-trip', () {
      final json = sampleTask.toLocalJson();
      final restored = TaskModel.fromLocalJson(json);
      expect(restored.id, sampleTask.id);
      expect(restored.title, sampleTask.title);
      expect(restored.description, sampleTask.description);
      expect(restored.status, sampleTask.status);
      expect(restored.userId, sampleTask.userId);
    });

    test('copyWith preserves unmodified fields', () {
      final copy = sampleTask.copyWith(title: 'Updated');
      expect(copy.title, 'Updated');
      expect(copy.description, sampleTask.description);
      expect(copy.status, sampleTask.status);
      expect(copy.id, sampleTask.id);
    });

    test('copyWith clearDueDate removes dueDate', () {
      final withDate = sampleTask.copyWith(dueDate: DateTime(2025, 12, 31));
      final cleared = withDate.copyWith(clearDueDate: true);
      expect(cleared.dueDate, isNull);
    });
  });

  // ── Validators ────────────────────────────────────────────────────────────

  group('Validators', () {
    group('validateTitle', () {
      test('returns error for empty string', () {
        expect(Validators.validateTitle(''), isNotNull);
        expect(Validators.validateTitle(null), isNotNull);
        expect(Validators.validateTitle('  '), isNotNull);
      });

      test('returns error when shorter than 3 chars', () {
        expect(Validators.validateTitle('ab'), isNotNull);
      });

      test('returns null for valid title', () {
        expect(Validators.validateTitle('Buy milk'), isNull);
      });

      test('returns error when longer than 100 chars', () {
        expect(Validators.validateTitle('a' * 101), isNotNull);
      });
    });

    group('validatePassword', () {
      test('returns error for empty password', () {
        expect(Validators.validatePassword(''), isNotNull);
        expect(Validators.validatePassword(null), isNotNull);
      });

      test('returns error for short password', () {
        expect(Validators.validatePassword('12345'), isNotNull);
      });

      test('returns null for valid password', () {
        expect(Validators.validatePassword('secret123'), isNull);
      });
    });

    group('validateEmail', () {
      test('returns error for invalid email', () {
        expect(Validators.validateEmail('notanemail'), isNotNull);
        expect(Validators.validateEmail('bad@'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(Validators.validateEmail('user@example.com'), isNull);
      });
    });

    group('validateConfirmPassword', () {
      test('returns error when passwords do not match', () {
        expect(
          Validators.validateConfirmPassword('abc123', 'different'),
          isNotNull,
        );
      });

      test('returns null when passwords match', () {
        expect(
          Validators.validateConfirmPassword('secret', 'secret'),
          isNull,
        );
      });
    });
  });
}
