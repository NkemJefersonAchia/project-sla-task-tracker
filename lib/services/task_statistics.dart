import '../models/sla_status.dart';
import '../models/task.dart';
import 'sla_service.dart';

/// Everything the statistics screen reports, computed in one place.
///
/// Kept out of the widget deliberately: these are the only real calculations
/// in the app beyond the SLA rules, and keeping them here means they can be
/// unit tested against fixed dates instead of only being looked at on screen.
class TaskStatistics {
  const TaskStatistics({
    required this.total,
    required this.completed,
    required this.onTimeCount,
    required this.averageDaysToComplete,
    required this.slaCounts,
  });

  final int total;
  final int completed;

  /// Completed tasks that were finished on or before their deadline.
  final int onTimeCount;

  /// Mean days from a task being created to being completed. Null when
  /// nothing has been completed yet - a zero would read as "instant", which
  /// is a different and wrong claim.
  final double? averageDaysToComplete;

  final Map<SlaStatus, int> slaCounts;

  /// Share of finished work that met its deadline, 0..1.
  ///
  /// Null when nothing is finished. A team with no completed tasks has no
  /// delivery rate; showing 0% would say they always miss, which is a
  /// different statement from having no record yet.
  double? get onTimeRate => completed == 0 ? null : onTimeCount / completed;

  int get lateCount => completed - onTimeCount;

  static TaskStatistics from(List<Task> tasks, {DateTime? now}) {
    final reference = now ?? DateTime.now();

    var completed = 0;
    var onTime = 0;
    var totalDays = 0;
    var measurable = 0;

    for (final task in tasks) {
      if (!task.status.isComplete) continue;
      completed++;

      final finishedAt = task.completedAt;
      if (finishedAt == null) {
        // Completed before the app started stamping completedAt. Counted as
        // done, but it cannot contribute to the timing figures.
        continue;
      }

      if (!Task.dateOnly(finishedAt).isAfter(Task.dateOnly(task.dueDate))) {
        onTime++;
      }

      final days = Task.dateOnly(finishedAt)
          .difference(Task.dateOnly(task.createdAt))
          .inDays;
      // A task created and finished the same day counts as a day of work,
      // not as zero, so the average cannot be dragged below one by quick wins.
      totalDays += days < 1 ? 1 : days;
      measurable++;
    }

    return TaskStatistics(
      total: tasks.length,
      completed: completed,
      onTimeCount: onTime,
      averageDaysToComplete: measurable == 0 ? null : totalDays / measurable,
      slaCounts: SlaService.summarise(tasks, now: reference),
    );
  }

  /// How much open work each member is carrying, worst-loaded first.
  ///
  /// Returns entries of (memberId, counts) so the caller resolves names -
  /// this layer never touches the member repository.
  static List<MapEntry<String, Map<SlaStatus, int>>> workloadByMember(
    List<Task> tasks,
    List<String> memberIds, {
    DateTime? now,
  }) {
    final rows = <MapEntry<String, Map<SlaStatus, int>>>[];

    for (final id in memberIds) {
      final theirs = tasks.where((t) => t.assigneeId == id).toList();
      rows.add(MapEntry(id, SlaService.summarise(theirs, now: now)));
    }

    // Most pressure first: overdue, then at risk, then sheer volume.
    rows.sort((a, b) {
      final byOverdue =
          (b.value[SlaStatus.overdue] ?? 0) - (a.value[SlaStatus.overdue] ?? 0);
      if (byOverdue != 0) return byOverdue;

      final byRisk =
          (b.value[SlaStatus.atRisk] ?? 0) - (a.value[SlaStatus.atRisk] ?? 0);
      if (byRisk != 0) return byRisk;

      final totalA = a.value.values.fold(0, (s, v) => s + v);
      final totalB = b.value.values.fold(0, (s, v) => s + v);
      return totalB - totalA;
    });

    return rows;
  }
}
