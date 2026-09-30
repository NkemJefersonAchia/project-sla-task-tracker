/// The SLA (service level agreement) classification of a task.
///
/// This value is **never stored**. It is recomputed from the task's deadline
/// and status every time it is needed, so it can never go stale — a task that
/// was "On Track" yesterday becomes "Overdue" today without anybody editing it.
/// See `lib/services/sla_service.dart` for the rules.
enum SlaStatus {
  onTrack('On Track'),
  atRisk('At Risk'),
  overdue('Overdue'),
  completed('Completed');

  const SlaStatus(this.label);

  final String label;

  /// Statuses the dashboard surfaces as "needs attention".
  bool get needsAttention =>
      this == SlaStatus.atRisk || this == SlaStatus.overdue;
}
