import '../models/task.dart';
import '../models/task_status.dart';
import '../services/seed_data.dart';
import '../services/storage_service.dart';

/// Single source of truth for tasks.
///
/// The repository keeps the whole collection in memory and mirrors every
/// change to local storage. Screens therefore read synchronously (no spinner
/// on every rebuild) while the `await`ed write guarantees the data is on disk
/// before the call returns.
///
/// It is a singleton because the dashboard, the list and the detail screen all
/// have to see the *same* objects - two copies would drift apart the moment a
/// status changed.
class TaskRepository {
  TaskRepository._();

  static final TaskRepository instance = TaskRepository._();

  final List<Task> _tasks = [];
  bool _loaded = false;

  /// Reads the stored tasks into memory. On the very first launch the store is
  /// empty, so we write the demo content once - that is what makes the app
  /// look alive during the demonstration instead of opening on a blank list.
  Future<void> load() async {
    if (_loaded) return;

    final storage = StorageService.instance;
    if (!storage.containsKey(StorageKeys.tasks)) {
      _tasks
        ..clear()
        ..addAll(SeedData.tasks());
      await _persist();
    } else {
      _tasks
        ..clear()
        ..addAll(storage.readJsonList(StorageKeys.tasks).map(Task.fromJson));
    }
    _loaded = true;
  }

  /// Every task, newest edit first. The list is unmodifiable so a screen can
  /// never mutate the repository's state behind its back.
  List<Task> get all => List.unmodifiable(_tasks);

  /// Returns the task with [id], or null if it has been deleted meanwhile.
  Task? byId(String id) {
    for (final task in _tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  /// Inserts [task] if its id is new, otherwise replaces the existing entry.
  /// One method for both cases keeps the create and edit screens identical.
  Future<void> save(Task task) async {
    final index = _tasks.indexWhere((existing) => existing.id == task.id);
    if (index == -1) {
      _tasks.add(task);
    } else {
      _tasks[index] = task;
    }
    await _persist();
  }

  /// Changes only the workflow status, stamping [Task.completedAt] the first
  /// time a task reaches Done and clearing it if the task is reopened.
  Future<Task?> updateStatus(String id, TaskStatus status) async {
    final current = byId(id);
    if (current == null) return null;

    final updated = current.copyWith(
      status: status,
      completedAt: status.isComplete ? DateTime.now() : null,
      clearCompletedAt: !status.isComplete,
      updatedAt: DateTime.now(),
    );
    await save(updated);
    return updated;
  }

  Future<void> delete(String id) async {
    _tasks.removeWhere((task) => task.id == id);
    await _persist();
  }

  /// Tasks belonging to one member - used by the profile and team screens.
  List<Task> byAssignee(String memberId) =>
      _tasks.where((task) => task.assigneeId == memberId).toList();

  /// Generates an id that is unique enough for a local-only app: the
  /// millisecond timestamp of creation, which cannot repeat on one device.
  String newId() => 'task_${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _persist() => StorageService.instance.writeJsonList(
        StorageKeys.tasks,
        _tasks.map((task) => task.toJson()).toList(),
      );

  /// Test hook: drops the in-memory cache so the next [load] re-reads storage.
  void resetForTesting() {
    _tasks.clear();
    _loaded = false;
  }
}
