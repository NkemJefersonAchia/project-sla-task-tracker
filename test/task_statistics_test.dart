import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/models/sla_status.dart';
import 'package:project_sla_task_tracker/models/task.dart';
import 'package:project_sla_task_tracker/models/task_priority.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/services/task_statistics.dart';

/// Tests for the statistics calculations.
///
/// `from` takes `now`, so every case below pins a fixed date and gives the
/// same answer whenever it is run.
void main() {
  final now = DateTime(2026, 6, 10);

  Task task({
    required String id,
    required TaskStatus status,
    required int createdDaysAgo,
    int dueInDays = 0,
    int? completedDaysAgo,
    String assigneeId = 'member_1',
  }) {
    final today = Task.dateOnly(now);
    return Task(
      id: id,
      title: 'Task $id',
      description: '',
      category: 'Testing',
      assigneeId: assigneeId,
      dueDate: today.add(Duration(days: dueInDays)),
      priority: TaskPriority.medium,
      status: status,
      createdAt: today.subtract(Duration(days: createdDaysAgo)),
      updatedAt: now,
      completedAt: completedDaysAgo == null
          ? null
          : today.subtract(Duration(days: completedDaysAgo)),
    );
  }

  group('on-time delivery', () {
    test('a task finished before its deadline counts as on time', () {
      final stats = TaskStatistics.from([
        task(
          id: 'a',
          status: TaskStatus.done,
          createdDaysAgo: 10,
          dueInDays: -2,
          completedDaysAgo: 5,
        ),
      ], now: now);

      expect(stats.completed, 1);
      expect(stats.onTimeCount, 1);
      expect(stats.onTimeRate, 1.0);
    });

    test('finishing exactly on the deadline still counts as on time', () {
      // The boundary that matters: delivering on the day you promised is
      // meeting the deadline, not missing it.
      final stats = TaskStatistics.from([
        task(
          id: 'a',
          status: TaskStatus.done,
          createdDaysAgo: 10,
          dueInDays: -3,
          completedDaysAgo: 3,
        ),
      ], now: now);

      expect(stats.onTimeCount, 1);
    });

    test('a task finished after its deadline counts as late', () {
      final stats = TaskStatistics.from([
        task(
          id: 'a',
          status: TaskStatus.done,
          createdDaysAgo: 10,
          dueInDays: -5,
          completedDaysAgo: 1,
        ),
      ], now: now);

      expect(stats.onTimeCount, 0);
      expect(stats.lateCount, 1);
      expect(stats.onTimeRate, 0.0);
    });

    test('unfinished work is not counted either way', () {
      final stats = TaskStatistics.from([
        task(id: 'a', status: TaskStatus.todo, createdDaysAgo: 10,
            dueInDays: -5),
        task(id: 'b', status: TaskStatus.inProgress, createdDaysAgo: 2,
            dueInDays: 5),
      ], now: now);

      expect(stats.completed, 0);
      expect(stats.total, 2);
    });

    test('no completed work reports no rate rather than zero percent', () {
      // 0% would claim the team always misses. Having no record is a
      // different statement, and the UI renders it differently.
      final stats = TaskStatistics.from([
        task(id: 'a', status: TaskStatus.todo, createdDaysAgo: 1,
            dueInDays: 3),
      ], now: now);

      expect(stats.onTimeRate, isNull);
      expect(stats.averageDaysToComplete, isNull);
    });

    test('a completed task with no completedAt stamp still counts as done',
        () {
      // Records written before the app stamped completedAt. They count as
      // completed but cannot contribute to the timing figures.
      final stats = TaskStatistics.from([
        task(id: 'a', status: TaskStatus.done, createdDaysAgo: 9,
            dueInDays: -1),
      ], now: now);

      expect(stats.completed, 1);
      expect(stats.onTimeCount, 0);
      expect(stats.averageDaysToComplete, isNull);
    });
  });

  group('average turnaround', () {
    test('is the mean days from created to completed', () {
      final stats = TaskStatistics.from([
        task(id: 'a', status: TaskStatus.done, createdDaysAgo: 10,
            dueInDays: -2, completedDaysAgo: 6), // 4 days
        task(id: 'b', status: TaskStatus.done, createdDaysAgo: 8,
            dueInDays: -2, completedDaysAgo: 2), // 6 days
      ], now: now);

      expect(stats.averageDaysToComplete, 5.0);
    });

    test('a same-day task counts as one day, not zero', () {
      // Otherwise a burst of quick wins drags the average below a day, which
      // reads as instantaneous delivery.
      final stats = TaskStatistics.from([
        task(id: 'a', status: TaskStatus.done, createdDaysAgo: 3,
            dueInDays: 0, completedDaysAgo: 3),
      ], now: now);

      expect(stats.averageDaysToComplete, 1.0);
    });
  });

  group('workload by member', () {
    test('puts whoever has overdue work first', () {
      final tasks = [
        task(id: 'a', status: TaskStatus.todo, createdDaysAgo: 5,
            dueInDays: -3, assigneeId: 'busy'),
        task(id: 'b', status: TaskStatus.todo, createdDaysAgo: 5,
            dueInDays: 20, assigneeId: 'calm'),
        task(id: 'c', status: TaskStatus.todo, createdDaysAgo: 5,
            dueInDays: 25, assigneeId: 'calm'),
      ];

      final rows = TaskStatistics.workloadByMember(
        tasks,
        ['calm', 'busy'],
        now: now,
      );

      // 'calm' has more tasks, but 'busy' has the overdue one.
      expect(rows.first.key, 'busy');
    });

    test('a member with nothing assigned still gets a row', () {
      final rows = TaskStatistics.workloadByMember(
        const [],
        ['nobody'],
        now: now,
      );

      expect(rows, hasLength(1));
      expect(rows.first.value[SlaStatus.overdue], 0);
    });
  });
}
