/// Every named route in the app.
///
/// Using constants instead of raw strings means a typo is a compile error
/// rather than a black screen at runtime, and it gives one list of the app's
/// navigable surface.
abstract final class AppRoutes {
  /// Decides at start-up whether to show sign-in or go straight to the app.
  static const String splash = '/';

  static const String signIn = '/sign-in';

  /// The shell that hosts the four bottom-navigation destinations.
  static const String home = '/home';

  /// Pushed on top of the shell. Takes a [TaskDetailArgs].
  static const String taskDetail = '/task/detail';

  /// Pushed on top of the shell. Takes a [TaskFormArgs]; a null task id means
  /// "create", a non-null one means "edit".
  static const String taskForm = '/task/form';

  /// Pushed from the dashboard and the profile screen.
  static const String statistics = '/statistics';
}

/// Arguments for [AppRoutes.taskDetail].
///
/// Only the id travels between screens, never the whole [Task] object. The
/// detail screen re-reads the task from the repository, so it can never show
/// a stale copy of something that was edited elsewhere.
class TaskDetailArgs {
  const TaskDetailArgs(this.taskId);

  final String taskId;
}

/// Arguments for [AppRoutes.taskForm].
class TaskFormArgs {
  /// Opens the form empty, ready to create a task.
  const TaskFormArgs.create() : taskId = null;

  /// Opens the form pre-filled with the task to edit.
  const TaskFormArgs.edit(this.taskId);

  final String? taskId;

  bool get isEditing => taskId != null;
}
