import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/models/sla_status.dart';
import 'package:project_sla_task_tracker/models/task.dart';
import 'package:project_sla_task_tracker/models/task_priority.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/services/task_query.dart';

/// Tests for the task list's filtering and sorting.
///
/// Because the logic lives in a plain value object rather than inside the
/// screen's State, the whole search + filter + sort behaviour can be checked
/// without building a single widget.
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
    int updatedDaysAgo = 0,
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
      updatedAt: now.subtract(Duration(days: updatedDaysAgo)),
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
      updatedDaysAgo: 2,
    ),
    task(
      id: '3',
      title: 'Write the demo script',
      category: 'Documentation',
      description: 'Covers the login flow end to end',
      assigneeId: 'member_2',
      dueInDays: 1,
      updatedDaysAgo: 5,
    ),
    task(
      id: '4',
      title: 'Accessibility review',
      category: 'QA',
      assigneeId: 'member_2',
      dueInDays: -8,
      status: TaskStatus.done,
      updatedDaysAgo: 1,
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

  group('filters', () {
    test('filtering by SLA state uses the live evaluation', () {
      final result = const TaskQuery(slaFilter: SlaStatus.overdue)
          .apply(tasks, now: now);

      expect(result.single.id, '2');
    });

    test('filtering by assignee', () {
      final result =
          const TaskQuery(assigneeFilter: 'member_2').apply(tasks, now: now);

      expect(result.map((t) => t.id), ['3', '4']);
    });

    test('filters combine as AND, not OR', () {
      final result = const TaskQuery(
        assigneeFilter: 'member_2',
        slaFilter: SlaStatus.completed,
      ).apply(tasks, now: now);

      expect(result.single.id, '4');
    });
  });

  group('sorting', () {
    test('urgency puts overdue first and completed last', () {
      final result = const TaskQuery().apply(tasks, now: now);

      expect(result.first.id, '2', reason: 'the overdue task leads');
      expect(result.last.id, '4', reason: 'completed work sinks to the end');
    });

    test('deadline sort is strictly by date', () {
      final result =
          const TaskQuery(sort: TaskSort.dueDateAsc).apply(tasks, now: now);

      expect(result.map((t) => t.id), ['4', '2', '3', '1']);
    });

    test('recently updated sort is newest first', () {
      final result = const TaskQuery(sort: TaskSort.recentlyUpdated)
          .apply(tasks, now: now);

      expect(result.first.id, '1');
      expect(result.last.id, '3');
    });

    test('title sort ignores case', () {
      final result =
          const TaskQuery(sort: TaskSort.titleAsc).apply(tasks, now: now);

      expect(result.first.title, 'Accessibility review');
    });
  });

  group('active filter reporting', () {
    test('a default query reports no active filters', () {
      expect(const TaskQuery().hasActiveFilters, isFalse);
      expect(const TaskQuery().activeFilterCount, 0);
    });

    test('the search term counts as active but not as a filter chip', () {
      const query = TaskQuery(searchTerm: 'login');

      expect(query.hasActiveFilters, isTrue);
      expect(query.activeFilterCount, 0);
    });

    test('copyWith can clear a filter that copyWith cannot null out', () {
      const query = TaskQuery(slaFilter: SlaStatus.atRisk);

      expect(query.copyWith(clearSla: true).slaFilter, isNull);
    });
  });

  test('applying a query never mutates the source list', () {
    final source = [...tasks];
    const TaskQuery(sort: TaskSort.titleAsc).apply(source, now: now);

    expect(source.map((t) => t.id), ['1', '2', '3', '4']);
  });
}
