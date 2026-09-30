import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/task_priority.dart';

/// The outcome of evaluating one task against the SLA rules.
///
/// It carries the [status] the UI paints, the [daysRemaining] it was derived
/// from, and a plain-English [explanation] we show on the task detail screen
/// so a user never has to guess *why* their task turned yellow or red.
class SlaEvaluation {
  const SlaEvaluation({
    required this.status,
    required this.daysRemaining,
    required this.explanation,
  });

  final SlaStatus status;

  /// Whole days between today and the deadline. Negative means the deadline
  /// has already passed, `0` means the task is due today.
  final int daysRemaining;

  final String explanation;
}

/// Turns a task's deadline and workflow status into an SLA classification.
///
/// ## The rules, in priority order
///
/// 1. **Completed** - the task is marked Done. Finished work is never chased,
///    even if it landed late.
/// 2. **Overdue** - the deadline is in the past and the task is not Done.
/// 3. **At Risk** - the deadline is close. "Close" depends on priority: an
///    Urgent task gets flagged 4 days out, a Low priority one only 1 day out,
///    because important work needs more warning time to recover.
/// 4. **At Risk** - the task has not been started at all (still "To Do") and
///    the deadline is inside [_notStartedWindowDays]. A task nobody has picked
///    up is at risk even if the raw deadline still looks comfortable.
/// 5. **On Track** - everything else.
///
/// The whole class is pure and static: same inputs, same output, no I/O. That
/// is what makes it straightforward to unit test (see
/// `test/sla_service_test.dart`) and why the SLA value is never persisted.
abstract final class SlaService {
  /// How many days before the deadline a task starts being flagged, per
  /// priority. Tuning the SLA policy means editing this one map.
  static const Map<TaskPriority, int> _riskWindowDays = {
    TaskPriority.urgent: 4,
    TaskPriority.high: 3,
    TaskPriority.medium: 2,
    TaskPriority.low: 1,
  };

  /// A task still sitting in "To Do" this close to its deadline is flagged
  /// regardless of priority.
  static const int _notStartedWindowDays = 3;

  /// Evaluates [task]. [now] is injectable so tests can pin "today" instead of
  /// depending on the real clock.
  static SlaEvaluation evaluate(Task task, {DateTime? now}) {
    final today = Task.dateOnly(now ?? DateTime.now());
    final due = Task.dateOnly(task.dueDate);
    final daysRemaining = due.difference(today).inDays;

    // Rule 1 - finished work.
    if (task.status.isComplete) {
      return SlaEvaluation(
        status: SlaStatus.completed,
        daysRemaining: daysRemaining,
        explanation: 'This task is done and no longer tracked against its '
            'deadline.',
      );
    }

    // Rule 2 - the deadline has passed.
    if (daysRemaining < 0) {
      final late = daysRemaining.abs();
      return SlaEvaluation(
        status: SlaStatus.overdue,
        daysRemaining: daysRemaining,
        explanation: 'The deadline passed ${_days(late)} ago and the task is '
            'still ${task.status.label.toLowerCase()}.',
      );
    }

    // Rule 3 - deadline is inside the priority's warning window.
    final riskWindow = _riskWindowDays[task.priority] ?? 2;
    if (daysRemaining <= riskWindow) {
      return SlaEvaluation(
        status: SlaStatus.atRisk,
        daysRemaining: daysRemaining,
        explanation: daysRemaining == 0
            ? 'Due today and not finished yet.'
            : 'Only ${_days(daysRemaining)} left, and '
                '${task.priority.label} priority work is flagged '
                '${_days(riskWindow)} before the deadline.',
      );
    }

    // Rule 4 - nobody has started it and the deadline is approaching.
    if (task.status.isNotStarted && daysRemaining <= _notStartedWindowDays) {
      return SlaEvaluation(
        status: SlaStatus.atRisk,
        daysRemaining: daysRemaining,
        explanation: 'Work has not started yet and the deadline is '
            '${_days(daysRemaining)} away.',
      );
    }

    // Rule 5 - comfortable.
    return SlaEvaluation(
      status: SlaStatus.onTrack,
      daysRemaining: daysRemaining,
      explanation: 'On schedule with ${_days(daysRemaining)} to spare.',
    );
  }

  /// Convenience wrapper when only the classification is needed.
  static SlaStatus statusOf(Task task, {DateTime? now}) =>
      evaluate(task, now: now).status;

  /// Counts how many tasks fall into each SLA bucket. Used by the dashboard
  /// metric tiles and by the statistics screen.
  static Map<SlaStatus, int> summarise(List<Task> tasks, {DateTime? now}) {
    final counts = {for (final status in SlaStatus.values) status: 0};
    for (final task in tasks) {
      final status = statusOf(task, now: now);
      counts[status] = counts[status]! + 1;
    }
    return counts;
  }

  static String _days(int count) => count == 1 ? '1 day' : '$count days';
}
