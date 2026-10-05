import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/sla_status.dart';

/// The horizontal row of SLA filters above the task list.
///
/// A scrolling row rather than a Wrap: five chips do not fit across a narrow
/// phone, and a second row of chips would push the list itself below the fold.
class SlaFilterBar extends StatelessWidget {
  const SlaFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// Null means "All".
  final SlaStatus? selected;

  final ValueChanged<SlaStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        children: [
          _Chip(
            label: 'All',
            selected: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final status in SlaStatus.values)
            _Chip(
              label: status.label,
              selected: selected == status,
              onTap: () => onSelected(status),
            ),
        ],
      ),
    );
  }
}

/// One filter chip.
///
/// Selected state is the ink colour filled in, not a tinted accent. Notion
/// marks the active item by making it the darkest thing in the row rather
/// than the most colourful, which keeps the SLA colours meaning only one
/// thing - the status of a task.
class _Chip extends StatelessWidget {
  const _Chip({
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: selected ? c.textPrimary : c.border),
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
      ),
    );
  }
}
