/// How important a task is relative to the rest of the backlog.
///
/// Priority also feeds the SLA rules: higher priority work is flagged as
/// "At Risk" earlier, because it has less room to slip.
enum TaskPriority {
  low('low', 'Low', 1),
  medium('medium', 'Medium', 2),
  high('high', 'High', 3),
  urgent('urgent', 'Urgent', 4);

  const TaskPriority(this.storageKey, this.label, this.weight);

  final String storageKey;
  final String label;

  /// Used to sort the task list so the most important work floats to the top.
  final int weight;

  static TaskPriority fromStorage(String? key) =>
      TaskPriority.values.firstWhere(
        (priority) => priority.storageKey == key,
        orElse: () => TaskPriority.medium,
      );
}
