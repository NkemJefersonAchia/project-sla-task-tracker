import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../models/sla_status.dart';
import '../../models/task_status.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/sla_service.dart';
import '../../services/storage_service.dart';
import '../../services/task_query.dart';
import '../../widgets/common/app_buttons.dart';
import '../../widgets/common/app_feedback.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/task/task_list_tile.dart';
import 'widgets/task_filter_sheet.dart';

/// The full task list: search, filter, sort, and complete tasks in place.
///
/// The screen holds exactly one piece of state - a [TaskQuery] - and derives
/// everything it shows from it. That is why the filter logic could be moved
/// out into `services/task_query.dart` and tested without a widget test.
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key, required this.onDataChanged});

  final VoidCallback onDataChanged;

  @override
  State<TaskListScreen> createState() => TaskListScreenState();
}

/// Public so [HomeShell] can drive the filter from the dashboard through a
/// `GlobalKey`. Every other State in the app is private.
class TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();

  TaskQuery _query = const TaskQuery();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Called by the shell when a dashboard metric tile is tapped.
  void applySlaFilter(SlaStatus? status) {
    setState(() {
      _query = status == null
          ? _query.copyWith(clearSla: true)
          : _query.copyWith(slaFilter: status);
    });
  }

  void _setSearchTerm(String value) {
    setState(() => _query = _query.copyWith(searchTerm: value));
  }

  Future<void> _openFilterSheet() async {
    final result = await TaskFilterSheet.show(context, _query);
    if (result != null) setState(() => _query = result);
  }

  Future<void> _openTask(String taskId) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.taskDetail,
      arguments: TaskDetailArgs(taskId),
    );
    _refresh();
  }

  Future<void> _createTask() async {
    final created = await Navigator.of(context).pushNamed<bool>(
      AppRoutes.taskForm,
      arguments: const TaskFormArgs.create(),
    );
    if (created == true) _refresh();
  }

  /// Flips a task between Done and To Do straight from the list.
  ///
  /// The write is awaited so the snack bar only appears once the change has
  /// actually reached local storage - a confirmation that lies is worse than
  /// no confirmation.
  Future<void> _toggleComplete(String taskId) async {
    final task = TaskRepository.instance.byId(taskId);
    if (task == null) return;

    final nextStatus =
        task.status.isComplete ? TaskStatus.todo : TaskStatus.done;

    try {
      await TaskRepository.instance.updateStatus(taskId, nextStatus);
      if (!mounted) return;
      _refresh();
      AppFeedback.showSuccess(
        context,
        nextStatus.isComplete
            ? 'Completed "${task.title}".'
            : 'Reopened "${task.title}".',
      );
    } on StorageException catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error.message);
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    widget.onDataChanged();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final allTasks = TaskRepository.instance.all;
    final visibleTasks = _query.apply(allTasks);

    return Scaffold(
      backgroundColor: c.canvas,
      floatingActionButton: FloatingActionButton(
        // The dashboard and the task list are both alive inside the shell's
        // IndexedStack, so their FABs need distinct hero tags - two heroes
        // sharing the default tag throws the moment a route is pushed.
        heroTag: 'task-list-new-task',
        onPressed: _createTask,
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
      body: Column(
        children: [
          _Header(
            total: allTasks.length,
            visible: visibleTasks.length,
            hasFilters: _query.hasActiveFilters,
          ),
          _SearchBar(
            controller: _searchController,
            onChanged: _setSearchTerm,
            onClear: () {
              _searchController.clear();
              _setSearchTerm('');
            },
            onFilterTap: _openFilterSheet,
            activeFilterCount: _query.activeFilterCount,
          ),
          _SlaFilterBar(
            selected: _query.slaFilter,
            // Counting is delegated to the same service the dashboard uses,
            // so the numbers on the two screens can never disagree.
            counts: SlaService.summarise(allTasks),
            onSelected: applySlaFilter,
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
                      AppSpacing.xxl * 2.5,
                    ),
                    itemCount: visibleTasks.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final task = visibleTasks[index];
                      return TaskListTile(
                        task: task,
                        assignee:
                            MemberRepository.instance.byId(task.assigneeId),
                        onTap: () => _openTask(task.id),
                        onToggleComplete: () => _toggleComplete(task.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Two different empty states: "you have no tasks" is a different problem
  /// from "your filters match nothing", and each needs a different way out.
  Widget _buildEmptyState() {
    // Centred here because this one sits inside an Expanded, where there is
    // real vertical space to centre within.
    if (_query.hasActiveFilters) {
      return Center(
        child: EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: 'No tasks match these filters',
          message: 'Try a different search term, or clear the filters to see '
              'the whole board again.',
          action: SecondaryButton(
            label: 'Clear filters',
            expand: false,
            onPressed: () {
              _searchController.clear();
              setState(() => _query = TaskQuery(sort: _query.sort));
            },
          ),
        ),
      );
    }

    return Center(
      child: EmptyState(
        icon: Icons.checklist_rounded,
        title: 'No tasks yet',
        message: 'Add the first piece of work and the SLA tracking starts '
            'straight away.',
        action: PrimaryButton(
          label: 'New task',
          icon: Icons.add_rounded,
          expand: false,
          onPressed: _createTask,
        ),
      ),
    );
  }

}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.visible,
    required this.hasFilters,
  });

  final int total;
  final int visible;
  final bool hasFilters;

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
          Expanded(
            child: Text('Tasks', style: AppTypography.pageTitle),
          ),
          Text(
            hasFilters ? '$visible of $total' : '$total total',
            style: AppTypography.caption.copyWith(color: c.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
    required this.activeFilterCount,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search title, category or description',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                isDense: true,
                // The clear button only exists while there is something to
                // clear, so the field is not permanently cluttered.
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        tooltip: 'Clear search',
                        onPressed: onClear,
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _FilterButton(
            onTap: onFilterTap,
            activeCount: activeFilterCount,
          ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap, required this.activeCount});

  final VoidCallback onTap;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final active = activeCount > 0;

    return Material(
      color: active ? c.blueBg : c.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: active ? c.blue : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                size: 17,
                color: active ? c.blue : c.textSecondary,
              ),
              if (active) ...[
                const SizedBox(width: 5),
                Text(
                  '$activeCount',
                  style: AppTypography.badge.copyWith(
                    color: c.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The horizontal row of SLA filters - the quickest way to answer "what is
/// overdue?" without opening the filter sheet.
class _SlaFilterBar extends StatelessWidget {
  const _SlaFilterBar({
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final SlaStatus? selected;
  final Map<SlaStatus, int> counts;
  final ValueChanged<SlaStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final total = counts.values.fold(0, (sum, value) => sum + value);

    return SizedBox(
      height: 46,
      // A horizontal ListView rather than a Wrap: five chips do not fit on a
      // narrow phone, and scrolling them is better than a second row that
      // pushes the task list down.
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
          vertical: AppSpacing.sm,
        ),
        children: [
          _SlaChip(
            label: 'All',
            count: total,
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final status in SlaStatus.values)
            _SlaChip(
              label: status.label,
              count: counts[status] ?? 0,
              status: status,
              selected: selected == status,
              onTap: () => onSelected(status),
            ),
        ],
      ),
    );
  }
}

class _SlaChip extends StatelessWidget {
  const _SlaChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.status,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final SlaStatus? status;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: selected ? c.textPrimary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected ? c.textPrimary : c.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: selected ? c.canvas : c.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: AppTypography.badge.copyWith(
                    color: selected ? c.canvas : c.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
