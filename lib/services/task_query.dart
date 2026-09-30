import '../models/sla_status.dart';
import '../models/task.dart';
import '../services/sla_service.dart';

/// A declarative description of what the task list should show.
///
/// Two controls, because two are enough: type to search, or tap an SLA chip.
/// A priority/assignee/sort sheet was tried and cut - on a board this size it
/// was three taps to reproduce what the urgency sort already does for free.
///
/// Keeping the filters in a value object - instead of loose fields on the
/// screen's State - means the screen holds exactly one piece of filter state,
/// and it lets [apply] be unit tested with no widgets at all.
class TaskQuery {
  const TaskQuery({this.searchTerm = '', this.slaFilter});

  /// Matched against the title, the category and the description.
  final String searchTerm;

  /// Null means "All".
  final SlaStatus? slaFilter;

  bool get hasActiveFilters => searchTerm.isNotEmpty || slaFilter != null;

  TaskQuery copyWith({
    String? searchTerm,
    SlaStatus? slaFilter,
    bool clearSla = false,
  }) {
    return TaskQuery(
      searchTerm: searchTerm ?? this.searchTerm,
      slaFilter: clearSla ? null : (slaFilter ?? this.slaFilter),
    );
  }

  /// Filters [tasks] and returns them most-urgent first.
  ///
  /// [now] is threaded through to [SlaService] so the SLA filter and the sort
  /// both judge every task against the same "today".
  List<Task> apply(List<Task> tasks, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final term = searchTerm.trim().toLowerCase();

    final filtered = tasks.where((task) {
      if (term.isNotEmpty && !_matchesSearch(task, term)) return false;
      if (slaFilter != null &&
          SlaService.statusOf(task, now: reference) != slaFilter) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) => _byUrgency(a, b, reference));
    return filtered;
  }

  bool _matchesSearch(Task task, String term) {
    return task.title.toLowerCase().contains(term) ||
        task.category.toLowerCase().contains(term) ||
        task.description.toLowerCase().contains(term);
  }

  /// Overdue first, then At Risk, then On Track, with Completed last - the
  /// list should open on the work that actually needs a decision. Ties break
  /// on priority, then on the nearest deadline.
  static int _byUrgency(Task a, Task b, DateTime now) {
    final bySla = _urgencyRank(a, now).compareTo(_urgencyRank(b, now));
    if (bySla != 0) return bySla;

    final byPriority = b.priority.weight.compareTo(a.priority.weight);
    if (byPriority != 0) return byPriority;

    return a.dueDate.compareTo(b.dueDate);
  }

  static int _urgencyRank(Task task, DateTime now) {
    switch (SlaService.statusOf(task, now: now)) {
      case SlaStatus.overdue:
        return 0;
      case SlaStatus.atRisk:
        return 1;
      case SlaStatus.onTrack:
        return 2;
      case SlaStatus.completed:
        return 3;
    }
  }
}
