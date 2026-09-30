/// Where a task currently sits in the team's workflow.
///
/// This is the value the *user* controls. It is deliberately separate from
/// [SlaStatus], which the app derives on its own from the status + deadline.
enum TaskStatus {
  todo('todo', 'To Do'),
  inProgress('in_progress', 'In Progress'),
  inReview('in_review', 'In Review'),
  done('done', 'Done');

  const TaskStatus(this.storageKey, this.label);

  /// Stable string written to local storage. We never persist `index`, so
  /// re-ordering or inserting a value cannot corrupt already-saved data.
  final String storageKey;

  /// Human readable name shown in the UI.
  final String label;

  /// A task is "finished work" only when it reaches [done].
  bool get isComplete => this == TaskStatus.done;

  /// Nothing has been started yet — used by the SLA rules to flag work that is
  /// still untouched close to its deadline.
  bool get isNotStarted => this == TaskStatus.todo;

  static TaskStatus fromStorage(String? key) => TaskStatus.values.firstWhere(
        (status) => status.storageKey == key,
        orElse: () => TaskStatus.todo,
      );
}
