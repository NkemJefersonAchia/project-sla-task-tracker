/// Every named route in the app.
///
/// Constants instead of raw strings, so a typo is a compile error rather than
/// a blank screen at runtime, and so this file is a list of everywhere the app
/// can go.
///
/// ## Adding your own routes
///
/// Add the name here, then handle it in `core/navigation/app_router.dart`.
/// Both files are shared, so do it in one small commit early and push it -
/// that way nobody is editing the same lines as you a week later.
///
/// If your screen returns something when it closes - a form that pops `true`
/// after saving, say - build it as `Route<bool>` in the router. `pushNamed<T>`
/// casts the route it gets back, and a mismatch throws at runtime.
abstract final class AppRoutes {
  /// The shell that holds the four bottom-navigation tabs.
  static const String home = '/';

  /// One task in full. Takes a [TaskDetailArgs].
  static const String taskDetail = '/task/detail';

  /// Create or edit a task. Takes a [TaskFormArgs]; a null id means create.
  static const String taskForm = '/task/form';

  // The welcome / sign-in route goes here when that screen exists.
}

/// Arguments for [AppRoutes.taskDetail].
///
/// Only the id travels between screens, never the whole Task. The detail
/// screen re-reads the task from the repository on every build, so it cannot
/// show a stale copy of something the form edited a moment ago.
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
