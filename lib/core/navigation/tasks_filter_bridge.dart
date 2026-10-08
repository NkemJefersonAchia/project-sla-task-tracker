import 'package:flutter/foundation.dart';

import '../../models/sla_status.dart';

/// One request to show the Tasks tab filtered to an SLA state.
///
/// A new instance is created for every request. That is deliberate:
/// [ValueNotifier] only notifies when the value changes, and two taps on the
/// same counter must both reach the Tasks tab even though they ask for the
/// same filter.
class TasksFilterRequest {
  TasksFilterRequest(this.slaFilter);

  /// The SLA state to filter by, or null for "show all tasks".
  final SlaStatus? slaFilter;
}

/// The hand-over point between the Home dashboard and the Tasks tab.
///
/// Home (through `HomeShell`) calls [request] when a counter is tapped. The
/// Tasks tab listens to [requests] and applies the filter to its `TaskQuery`.
/// Neither screen needs to know about the other, and `HomeShell` stays the
/// only shared file that has to change.
abstract final class TasksFilterBridge {
  static final ValueNotifier<TasksFilterRequest?> requests =
      ValueNotifier<TasksFilterRequest?>(null);

  static void request(SlaStatus? slaFilter) {
    requests.value = TasksFilterRequest(slaFilter);
  }
}