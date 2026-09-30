import 'task_priority.dart';
import 'task_status.dart';

/// A single unit of work owned by one team member.
///
/// The class is immutable: every edit goes through [copyWith] and produces a
/// new instance. That makes it impossible to change a task by accident from
/// another screen, and it means `setState` always receives a genuinely new
/// object to rebuild from.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.assigneeId,
    required this.dueDate,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes = '',
    this.completedAt,
  });

  final String id;
  final String title;
  final String description;

  /// Free-text grouping such as "UI/UX Design" or "Backend".
  final String category;

  /// [TeamMember.id] of the owner. Empty string means unassigned.
  final String assigneeId;

  /// Deadline, stored date-only (midnight local time) - see [dateOnly].
  final DateTime dueDate;

  final TaskPriority priority;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Free-form notes captured on the detail screen.
  final String notes;

  /// When the task first reached [TaskStatus.done]. Kept so the statistics
  /// screen can later report whether work landed before or after its deadline.
  final DateTime? completedAt;

  /// Strips the time component so deadline comparisons are whole-day based.
  /// Without this, a task due "today" would already look overdue at 00:01.
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Task copyWith({
    String? title,
    String? description,
    String? category,
    String? assigneeId,
    DateTime? dueDate,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? updatedAt,
    String? notes,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      assigneeId: assigneeId ?? this.assigneeId,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'assigneeId': assigneeId,
        // ISO-8601 strings survive JSON round-trips and stay human readable
        // if we ever need to inspect what SharedPreferences is holding.
        'dueDate': dueDate.toIso8601String(),
        'priority': priority.storageKey,
        'status': status.storageKey,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'notes': notes,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Task(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled task',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      assigneeId: json['assigneeId'] as String? ?? '',
      dueDate: _parseDate(json['dueDate']) ?? now,
      priority: TaskPriority.fromStorage(json['priority'] as String?),
      status: TaskStatus.fromStorage(json['status'] as String?),
      createdAt: _parseDate(json['createdAt']) ?? now,
      updatedAt: _parseDate(json['updatedAt']) ?? now,
      notes: json['notes'] as String? ?? '',
      completedAt: _parseDate(json['completedAt']),
    );
  }

  /// Tolerant date parsing: a malformed or missing value returns null instead
  /// of throwing, so one corrupt record cannot stop the whole list loading.
  static DateTime? _parseDate(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
