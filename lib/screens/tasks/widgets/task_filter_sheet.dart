import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/task_priority.dart';
import '../../../repositories/member_repository.dart';
import '../../../services/task_query.dart';
import '../../../widgets/common/app_buttons.dart';
import '../../../widgets/common/section_header.dart';

/// Bottom sheet holding the filters that do not fit on the toolbar.
///
/// It edits a *draft copy* of the query and only returns it when the user
/// presses Apply, so backing out of the sheet leaves the list exactly as it
/// was. Returning `null` means "cancelled"; returning a [TaskQuery] means
/// "use this".
class TaskFilterSheet extends StatefulWidget {
  const TaskFilterSheet({super.key, required this.query});

  final TaskQuery query;

  /// Opens the sheet and resolves to the new query, or null if dismissed.
  static Future<TaskQuery?> show(BuildContext context, TaskQuery query) {
    return showModalBottomSheet<TaskQuery>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TaskFilterSheet(query: query),
    );
  }

  @override
  State<TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<TaskFilterSheet> {
  late TaskQuery _draft = widget.query;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final members = MemberRepository.instance.all;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.66,
      maxChildSize: 0.92,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Column(
          children: [
            const _SheetGrabber(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                0,
                AppSpacing.screenPadding,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter and sort',
                      style: AppTypography.sectionTitle.copyWith(
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  if (_draft.activeFilterCount > 0)
                    TextButton(
                      onPressed: () => setState(
                        () => _draft = TaskQuery(
                          searchTerm: _draft.searchTerm,
                          sort: _draft.sort,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: c.textSecondary,
                      ),
                      child: const Text('Reset'),
                    ),
                ],
              ),
            ),
            Divider(color: c.border, height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                children: [
                  SectionHeader(title: 'Priority'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ChoicePill(
                        label: 'Any',
                        selected: _draft.priorityFilter == null,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(clearPriority: true),
                        ),
                      ),
                      for (final priority in TaskPriority.values)
                        _ChoicePill(
                          label: priority.label,
                          selected: _draft.priorityFilter == priority,
                          onTap: () => setState(
                            () => _draft =
                                _draft.copyWith(priorityFilter: priority),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: 'Assignee'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ChoicePill(
                        label: 'Anyone',
                        selected: _draft.assigneeFilter == null,
                        onTap: () => setState(
                          () => _draft = _draft.copyWith(clearAssignee: true),
                        ),
                      ),
                      for (final member in members)
                        _ChoicePill(
                          label: member.name,
                          selected: _draft.assigneeFilter == member.id,
                          onTap: () => setState(
                            () => _draft =
                                _draft.copyWith(assigneeFilter: member.id),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: 'Sort by'),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final sort in TaskSort.values)
                        _ChoicePill(
                          label: sort.label,
                          selected: _draft.sort == sort,
                          onTap: () =>
                              setState(() => _draft = _draft.copyWith(sort: sort)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.md,
                AppSpacing.screenPadding,
                // Keeps the button clear of the home indicator on phones that
                // have one.
                AppSpacing.md + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: PrimaryButton(
                label: 'Apply',
                onPressed: () => Navigator.of(context).pop(_draft),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          height: 4,
          width: 36,
          decoration: BoxDecoration(
            color: c.borderStrong,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    );
  }
}

/// A selectable pill. Used for every choice in the sheet so priority,
/// assignee and sort all behave identically.
class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Material(
      color: selected ? c.textPrimary : c.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: selected ? c.canvas : c.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
