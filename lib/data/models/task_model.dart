enum TaskStatus { pending, inProgress, completed }

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  String get value {
    switch (this) {
      case TaskStatus.pending:
        return 'pending';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.completed:
        return 'completed';
    }
  }

  static TaskStatus fromString(String? value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'completed':
        return TaskStatus.completed;
      default:
        return TaskStatus.pending;
    }
  }

  static TaskStatus fromBool(bool completed) =>
      completed ? TaskStatus.completed : TaskStatus.pending;
}

class TaskModel {
  final int id;
  final String title;
  final String description;
  final TaskStatus status;
  final DateTime? dueDate;
  final int userId;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    this.dueDate,
    required this.userId,
    required this.createdAt,
  });

  bool get isOverdue =>
      dueDate != null &&
      status != TaskStatus.completed &&
      DateTime.now().isAfter(dueDate!);

  /// Build from DummyJSON API response, optionally merging local extra data.
  factory TaskModel.fromApiJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? extra,
  }) {
    final ex = extra ?? {};
    final TaskStatus status;
    if (ex['status'] != null) {
      status = TaskStatusX.fromString(ex['status'] as String?);
    } else {
      status = TaskStatusX.fromBool(json['completed'] as bool? ?? false);
    }
    return TaskModel(
      id: json['id'] as int,
      title: ex['title'] as String? ?? json['todo'] as String? ?? '',
      description: ex['description'] as String? ?? '',
      status: status,
      dueDate: ex['dueDate'] != null
          ? DateTime.tryParse(ex['dueDate'] as String)
          : null,
      userId: json['userId'] as int? ?? 0,
      createdAt: ex['createdAt'] != null
          ? DateTime.tryParse(ex['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  factory TaskModel.fromLocalJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: TaskStatusX.fromString(json['status'] as String?),
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : null,
      userId: json['userId'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toLocalJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.value,
        'dueDate': dueDate?.toIso8601String(),
        'userId': userId,
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toApiJson() => {
        'todo': title,
        'completed': status == TaskStatus.completed,
        'userId': userId,
      };

  TaskModel copyWith({
    String? title,
    String? description,
    TaskStatus? status,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      userId: userId,
      createdAt: createdAt,
    );
  }
}
