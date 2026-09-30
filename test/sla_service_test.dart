import 'package:flutter_test/flutter_test.dart';
import 'package:project_sla_task_tracker/models/sla_status.dart';
import 'package:project_sla_task_tracker/models/task.dart';
import 'package:project_sla_task_tracker/models/task_priority.dart';
import 'package:project_sla_task_tracker/models/task_status.dart';
import 'package:project_sla_task_tracker/services/sla_service.dart';

/// Tests for the SLA rules.
///
/// These are the rules the whole app is built around, so they are the part
/// worth testing directly. `SlaService` takes `now` as a parameter, which
/// means every case below pins "today" to a fixed date - the tests give the
/// same answer in a year's time as they do now.
void main() {
  // A fixed Wednesday to reason from.
  final now = DateTime(2026, 6, 10, 9, 30);

  Task taskDue(
    int daysFromNow, {
    TaskStatus status = TaskStatus.inProgress,
    TaskPriority priority = TaskPriority.medium,
  }) {
    return Task(
      id: 'test',
      title: 'Test task',
      description: '',
      category: 'Testing',
      assigneeId: 'member_1',
      dueDate: Task.dateOnly(now).add(Duration(days: daysFromNow)),
      priority: priority,
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('Rule 1 - completed work', () {
    test('a done task is Completed even when the deadline has passed', () {
      final task = taskDue(-30, status: TaskStatus.done);

      expect(
        SlaService.statusOf(task, now: now),
        SlaStatus.completed,
      );
    });

    test('completion wins over every other rule', () {
      final task = taskDue(
        -1,
        status: TaskStatus.done,
        priority: TaskPriority.urgent,
      );

      expect(SlaService.statusOf(task, now: now), SlaStatus.completed);
    });
  });

  group('Rule 2 - overdue', () {
    test('an unfinished task past its deadline is Overdue', () {
      expect(
        SlaService.statusOf(taskDue(-1), now: now),
        SlaStatus.overdue,
      );
    });

    test('the explanation reports how late the task is', () {
      final evaluation = SlaService.evaluate(taskDue(-4), now: now);

      expect(evaluation.daysRemaining, -4);
      expect(evaluation.explanation, contains('4 days'));
    });
  });

  group('Rule 3 - the priority warning window', () {
    test('due today is At Risk, not Overdue', () {
      // The boundary that matters most: a deadline of "today" has not passed.
      expect(SlaService.statusOf(taskDue(0), now: now), SlaStatus.atRisk);
    });

    test('medium priority is flagged 2 days out but not 3', () {
      expect(
        SlaService.statusOf(taskDue(2, priority: TaskPriority.medium),
            now: now),
        SlaStatus.atRisk,
      );
      expect(
        SlaService.statusOf(taskDue(3, priority: TaskPriority.medium),
            now: now),
        SlaStatus.onTrack,
      );
    });

    test('urgent work gets a wider window than low priority work', () {
      final deadline = 4;

      expect(
        SlaService.statusOf(
          taskDue(deadline, priority: TaskPriority.urgent),
          now: now,
        ),
        SlaStatus.atRisk,
      );
      expect(
        SlaService.statusOf(
          taskDue(deadline, priority: TaskPriority.low),
          now: now,
        ),
        SlaStatus.onTrack,
      );
    });
  });

  group('Rule 4 - work that has not started', () {
    test('a To Do task 3 days out is At Risk even at low priority', () {
      final task = taskDue(
        3,
        status: TaskStatus.todo,
        priority: TaskPriority.low,
      );

      // Rule 3 would say On Track for low priority at 3 days; rule 4 catches
      // it because nobody has picked the work up.
      expect(SlaService.statusOf(task, now: now), SlaStatus.atRisk);
    });

    test('the same task in progress is On Track', () {
      final task = taskDue(
        3,
        status: TaskStatus.inProgress,
        priority: TaskPriority.low,
      );

      expect(SlaService.statusOf(task, now: now), SlaStatus.onTrack);
    });

    test('a To Do task far out is still On Track', () {
      final task = taskDue(10, status: TaskStatus.todo);

      expect(SlaService.statusOf(task, now: now), SlaStatus.onTrack);
    });
  });

  group('Rule 5 - on track', () {
    test('a comfortable deadline reports the days remaining', () {
      final evaluation = SlaService.evaluate(taskDue(12), now: now);

      expect(evaluation.status, SlaStatus.onTrack);
      expect(evaluation.daysRemaining, 12);
    });
  });

  group('summarise', () {
    test('counts every task into exactly one bucket', () {
      final tasks = [
        taskDue(-2),
        taskDue(-5),
        taskDue(1),
        taskDue(20),
        taskDue(-9, status: TaskStatus.done),
      ];

      final counts = SlaService.summarise(tasks, now: now);

      expect(counts[SlaStatus.overdue], 2);
      expect(counts[SlaStatus.atRisk], 1);
      expect(counts[SlaStatus.onTrack], 1);
      expect(counts[SlaStatus.completed], 1);
      expect(
        counts.values.fold<int>(0, (sum, value) => sum + value),
        tasks.length,
      );
    });

    test('an empty project reports zero in every bucket', () {
      final counts = SlaService.summarise(const [], now: now);

      expect(counts.values.every((value) => value == 0), isTrue);
    });
  });

  group('time of day', () {
    test('a deadline today is not overdue late in the evening', () {
      // Deadlines are whole days. Without Task.dateOnly this case would flip
      // to Overdue at one minute past midnight.
      final lateEvening = DateTime(2026, 6, 10, 23, 59);

      expect(
        SlaService.statusOf(taskDue(0), now: lateEvening),
        SlaStatus.atRisk,
      );
    });
  });
}
