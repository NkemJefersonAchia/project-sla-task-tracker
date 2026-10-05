import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../repositories/member_repository.dart';
import '../../repositories/task_repository.dart';
import '../../services/task_query.dart';
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

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final allTasks = TaskRepository.instance.all;
    final visibleTasks = _query.apply(allTasks);

    return Scaffold(
      backgroundColor: c.canvas,
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
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.xxl,
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
                    assignee: MemberRepository.instance.byId(task.assigneeId),
                    onTap: () {},
                  );
                },
              ),
            ),
          ],
        ),
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
