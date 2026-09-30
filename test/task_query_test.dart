import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/models/sla_status.dart';
import 'package:project_sla_task_tracker/models/task.dart';
import 'package:project_sla_task_tracker/models/task_priority.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/services/task_query.dart';

/// Tests for the task list's searching, filtering and ordering.
///
/// Because the logic lives in a plain value object rather than inside the
/// screen's State, the whole behaviour can be checked without building a
/// single widget.
void main() {
  final now = DateTime(2026, 6, 10);

  Task task({
    required String id,
    required String title,
    String category = 'General',
    String description = '',
    String assigneeId = 'member_1',
    int dueInDays = 10,
    TaskPriority priority = TaskPriority.medium,
    TaskStatus status = TaskStatus.inProgress,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      category: category,
      assigneeId: assigneeId,
      dueDate: Task.dateOnly(now).add(Duration(days: dueInDays)),
      priority: priority,
      status: status,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
    );
  }

  final tasks = [
    task(id: '1', title: 'Design login screen', category: 'UI/UX'),
    task(
      id: '2',
      title: 'Local storage layer',
      category: 'Mobile',
      dueInDays: -3,
      priority: TaskPriority.high,
    ),
    task(
      id: '3',
      title: 'Write the demo script',
      category: 'Documentation',
      description: 'Covers the login flow end to end',
      assigneeId: 'member_2',
      dueInDays: 1,
    ),
    task(
      id: '4',
      title: 'Accessibility review',
      category: 'QA',
      assigneeId: 'member_2',
      dueInDays: -8,
      status: TaskStatus.done,
    ),
  ];

  group('search', () {
    test('matches the title, case-insensitively', () {
      final result =
          const TaskQuery(searchTerm: 'LOGIN').apply(tasks, now: now);

      // Task 3 matches on its description, task 1 on its title.
      expect(result.map((t) => t.id), containsAll(['1', '3']));
    });

    test('matches the category', () {
      final result =
          const TaskQuery(searchTerm: 'documentation').apply(tasks, now: now);

      expect(result.single.id, '3');
    });

    test('a term nothing matches returns an empty list, not everything', () {
      final result =
          const TaskQuery(searchTerm: 'zzzz').apply(tasks, now: now);

      expect(result, isEmpty);
    });

    test('whitespace-only search is treated as no search', () {
      final result = const TaskQuery(searchTerm: '   ').apply(tasks, now: now);

      expect(result, hasLength(tasks.length));
    });
  });

  group('SLA filter', () {
    test('uses the live evaluation rather than a stored value', () {
      final result = const TaskQuery(slaFilter: SlaStatus.overdue)
          .apply(tasks, now: now);

      expect(result.single.id, '2');
    });

    test('completed work can be isolated', () {
      final result = const TaskQuery(slaFilter: SlaStatus.completed)
          .apply(tasks, now: now);

      expect(result.single.id, '4');
    });

    test('search and the SLA filter combine as AND, not OR', () {
      final result = const TaskQuery(
        searchTerm: 'accessibility',
        slaFilter: SlaStatus.overdue,
      ).apply(tasks, now: now);

      // Task 4 matches the search but is Completed, not Overdue.
      expect(result, isEmpty);
    });
  });

  group('ordering', () {
    test('overdue leads and completed sinks to the end', () {
      final result = const TaskQuery().apply(tasks, now: now);

      expect(result.first.id, '2');
      expect(result.last.id, '4');
    });

    test('within one SLA bucket, higher priority wins', () {
      final sameBucket = [
        task(id: 'low', title: 'Low', dueInDays: 30, priority: TaskPriority.low),
        task(
          id: 'urgent',
          title: 'Urgent',
          dueInDays: 30,
          priority: TaskPriority.urgent,
        ),
      ];

      final result = const TaskQuery().apply(sameBucket, now: now);

      expect(result.first.id, 'urgent');
    });

    test('equal priority falls back to the nearest deadline', () {
      final sameBucket = [
        task(id: 'far', title: 'Far', dueInDays: 40),
        task(id: 'near', title: 'Near', dueInDays: 20),
      ];

      final result = const TaskQuery().apply(sameBucket, now: now);

      expect(result.first.id, 'near');
    });
  });

  group('active filter reporting', () {
    test('a default query reports nothing active', () {
      expect(const TaskQuery().hasActiveFilters, isFalse);
    });

    test('either control counts as active', () {
      expect(const TaskQuery(searchTerm: 'login').hasActiveFilters, isTrue);
      expect(
        const TaskQuery(slaFilter: SlaStatus.atRisk).hasActiveFilters,
        isTrue,
      );
    });

    test('copyWith can clear a filter that copyWith cannot null out', () {
      const query = TaskQuery(slaFilter: SlaStatus.atRisk);

      expect(query.copyWith(clearSla: true).slaFilter, isNull);
    });
  });

  test('applying a query never mutates the source list', () {
    final source = [...tasks];
    const TaskQuery(searchTerm: 'e').apply(source, now: now);

    expect(source.map((t) => t.id), ['1', '2', '3', '4']);
  });
}
