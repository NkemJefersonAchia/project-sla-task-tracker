import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/task_repository.dart';
import '../../models/sla_status.dart';
import '../../models/task_status.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../services/task_query.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/empty_state.dart';
import 'widgets/sla_filter_bar.dart';
import 'widgets/task_row.dart';

/// The Tasks tab: every task on the project, most urgent first.
///
/// The screen holds exactly one piece of state - a [TaskQuery] - and derives
/// everything it shows from it. That is what lets the filtering live in a
/// plain value object that can be unit tested without building a widget.
///
/// Task data is read from `TaskRepository.instance.all` inside `build`. The
/// repository is already in memory, so there is no future to await and no
/// spinner to show, and because nothing is cached here a change made on
/// another tab shows up the moment this one rebuilds.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();

  TaskQuery _query = const TaskQuery();

  @override
  void dispose() {
    // Controllers hold native resources. Not disposing one leaks it.
    _searchController.dispose();
    super.dispose();
  }

  void _setSearchTerm(String value) {
    setState(() => _query = _query.copyWith(searchTerm: value));
  }

  void _clearFilters() {
    _searchController.clear();
    setState(() => _query = const TaskQuery());
  }

  /// Flips a task between Done and To Do straight from the list.
  ///
  /// The write is awaited before the screen rebuilds, so what you see has
  /// actually reached storage rather than only the in-memory copy.
  Future<void> _toggleComplete(String taskId) async {
    final task = TaskRepository.instance.byId(taskId);
    if (task == null) return;

    final next = task.status.isComplete ? TaskStatus.todo : TaskStatus.done;

    try {
      await TaskRepository.instance.updateStatus(taskId, next);
      if (!mounted) return;
      setState(() {});
      AppFeedback.showSuccess(
        context,
        next.isComplete
            ? 'Completed "${task.title}".'
            : 'Reopened "${task.title}".',
      );
    } on StorageException catch (error) {
      // A failed write must not look like a success. The row is already
      // correct - it was never changed - so all that is needed is to say so.
      if (!mounted) return;
      AppFeedback.showError(context, error.message);
    }
  }

  /// Opens the create form. It pops `true` when something was saved, which is
  /// the signal to re-read; anything else means the user backed out.
  Future<void> _createTask() async {
    final saved = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.taskForm,
      arguments: const TaskFormArgs.create(),
    );
    if (saved == true && mounted) setState(() {});
  }

  void _setSlaFilter(SlaStatus? status) {
    setState(() {
      _query = status == null
          ? _query.copyWith(clearSla: true)
          : _query.copyWith(slaFilter: status);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final allTasks = TaskRepository.instance.all;
    final visibleTasks = _query.apply(allTasks);

    return Scaffold(
      backgroundColor: c.canvas,
      floatingActionButton: FloatingActionButton(
        onPressed: _createTask,
        // Every tab is alive at once inside the shell's IndexedStack, and
        // Flutter gives every FAB the same default hero tag. Two heroes
        // sharing a tag in one subtree throws the moment a route is pushed,
        // so this one is named.
        heroTag: 'tasks-new-task',
        backgroundColor: c.accent,
        foregroundColor: c.canvas,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        tooltip: 'New task',
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              total: allTasks.length,
              visible: visibleTasks.length,
              isFiltered: _query.hasActiveFilters,
            ),
            _SearchField(
              controller: _searchController,
              onChanged: _setSearchTerm,
              onClear: () {
                _searchController.clear();
                _setSearchTerm('');
              },
            ),
            const SizedBox(height: AppSpacing.md),
            SlaFilterBar(
              selected: _query.slaFilter,
              // Counted from every task, not from the filtered list, so the
              // numbers stay still while you move between chips. Same service
              // the dashboard uses, so the two screens cannot disagree.
              counts: SlaService.summarise(allTasks),
              onSelected: _setSlaFilter,
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: visibleTasks.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  // Clears the floating button at the end of the scroll so it
                  // never sits on top of the last row.
                  AppSpacing.xxl * 2.5,
                ),
                itemCount: visibleTasks.length,
                // A gap between rows rather than a divider: AppCard already
                // draws its own hairline, and a divider stacked on a border
                // gives a 2px line that reads as a rendering bug.
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final task = visibleTasks[index];
                  return TaskRow(
                    task: task,
                    assignee:
                        MemberRepository.instance.byId(task.assigneeId),
                    onTap: () {},
                    onToggleComplete: () => _toggleComplete(task.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// An empty list is not always the same problem.
  ///
  /// "You have no tasks" and "nothing matches your filters" need different
  /// wording and different ways out, so they are two states rather than one
  /// shrug. Centred because, unlike inside a ListView, there is real vertical
  /// space here to centre within.
  Widget _buildEmptyState() {
    if (_query.hasActiveFilters) {
      return Center(
        child: EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No tasks match',
          message: 'Try a different search term, or clear the filters to see '
              'the whole board again.',
          action: SecondaryButton(
            label: 'Clear filters',
            expand: false,
            onPressed: _clearFilters,
          ),
        ),
      );
    }

    return const Center(
      child: EmptyState(
        icon: Icons.checklist_rounded,
        title: 'No tasks yet',
        message: 'Add the first piece of work and the SLA tracking starts '
            'straight away.',
      ),
    );
  }
}

/// The page title and a live count.
///
/// Notion puts the page title in the body rather than in a chrome app bar, at
/// a size that makes it obviously a heading, with everything else quieter
/// around it. There is no AppBar on this screen for that reason.
class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.visible,
    required this.isFiltered,
  });

  final int total;
  final int visible;
  final bool isFiltered;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.lg,
        AppSpacing.screenPadding,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text('Tasks', style: AppTypography.pageTitle)),
          Text(
            // While a search is running, "3 of 12" is more useful than a bare
            // total - it says how much is being hidden.
            isFiltered
                ? '$visible of $total'
                : (total == 1 ? '1 task' : '$total tasks'),
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

/// Search across the title, the category and the description.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search tasks',
          prefixIcon: const Icon(Icons.search_rounded, size: 18),
          isDense: true,
          // The clear button only exists while there is something to clear,
          // so an empty field is not permanently cluttered by a dead control.
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  tooltip: 'Clear search',
                  onPressed: onClear,
                ),
        ),
      ),
    );
  }
}
