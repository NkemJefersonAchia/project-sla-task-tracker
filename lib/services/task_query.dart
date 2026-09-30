import '../models/sla_status.dart';
import '../models/task.dart';
import '../models/task_priority.dart';
import '../services/sla_service.dart';

/// How the task list is ordered.
enum TaskSort {
  urgency('Most urgent'),
  dueDateAsc('Deadline'),
  recentlyUpdated('Recently updated'),
  titleAsc('Title A-Z');

  const TaskSort(this.label);

  final String label;
}

/// A declarative description of what the task list should show.
///
/// Keeping the filters in a value object - instead of half a dozen loose
/// fields on the screen's State - means the screen holds exactly one piece of
/// filter state, and `copyWith` makes each `setState` call a single readable
/// line. It also lets [TaskQuery.apply] be unit tested with no widgets at all.
class TaskQuery {
  const TaskQuery({
    this.searchTerm = '',
    this.slaFilter,
    this.priorityFilter,
    this.assigneeFilter,
    this.sort = TaskSort.urgency,
  });

  /// Matched against the title, the category and the description.
  final String searchTerm;

  /// Null means "All".
  final SlaStatus? slaFilter;
  final TaskPriority? priorityFilter;
  final String? assigneeFilter;

  final TaskSort sort;

  /// True when anything other than the default sort is active - drives the
  /// "clear filters" affordance and the dot on the filter button.
  bool get hasActiveFilters =>
      searchTerm.isNotEmpty ||
      slaFilter != null ||
      priorityFilter != null ||
      assigneeFilter != null;

  int get activeFilterCount => [
        slaFilter,
        priorityFilter,
        assigneeFilter,
      ].where((filter) => filter != null).length;

  TaskQuery copyWith({
    String? searchTerm,
    SlaStatus? slaFilter,
    TaskPriority? priorityFilter,
    String? assigneeFilter,
    TaskSort? sort,
    bool clearSla = false,
    bool clearPriority = false,
    bool clearAssignee = false,
  }) {
    return TaskQuery(
      searchTerm: searchTerm ?? this.searchTerm,
      slaFilter: clearSla ? null : (slaFilter ?? this.slaFilter),
      priorityFilter:
          clearPriority ? null : (priorityFilter ?? this.priorityFilter),
      assigneeFilter:
          clearAssignee ? null : (assigneeFilter ?? this.assigneeFilter),
      sort: sort ?? this.sort,
    );
  }

  /// Filters and sorts [tasks] according to this query.
  ///
  /// [now] is threaded through to [SlaService] so the SLA filter and the
  /// urgency sort both judge every task against the same "today".
  List<Task> apply(List<Task> tasks, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final term = searchTerm.trim().toLowerCase();

    final filtered = tasks.where((task) {
      if (term.isNotEmpty && !_matchesSearch(task, term)) return false;
      if (priorityFilter != null && task.priority != priorityFilter) {
        return false;
      }
      if (assigneeFilter != null && task.assigneeId != assigneeFilter) {
        return false;
      }
      if (slaFilter != null &&
          SlaService.statusOf(task, now: reference) != slaFilter) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) => _compare(a, b, reference));
    return filtered;
  }

  bool _matchesSearch(Task task, String term) {
    return task.title.toLowerCase().contains(term) ||
        task.category.toLowerCase().contains(term) ||
        task.description.toLowerCase().contains(term);
  }

  int _compare(Task a, Task b, DateTime now) {
    switch (sort) {
      case TaskSort.urgency:
        // Overdue first, then At Risk, then On Track, with Completed last -
        // the list should open on the work that actually needs a decision.
        final bySla = _urgencyRank(a, now).compareTo(_urgencyRank(b, now));
        if (bySla != 0) return bySla;

        // Within the same bucket, heavier priority wins...
        final byPriority = b.priority.weight.compareTo(a.priority.weight);
        if (byPriority != 0) return byPriority;

        // ...and finally the nearest deadline.
        return a.dueDate.compareTo(b.dueDate);

      case TaskSort.dueDateAsc:
        return a.dueDate.compareTo(b.dueDate);

      case TaskSort.recentlyUpdated:
        return b.updatedAt.compareTo(a.updatedAt);

      case TaskSort.titleAsc:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
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
