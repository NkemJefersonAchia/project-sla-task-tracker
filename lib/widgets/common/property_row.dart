import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// A "property" line: a muted icon and label on the left, the value on the
/// right - the layout Notion uses under a page title.
///
/// The label column is a fixed width so that a stack of rows lines up into a
/// clean vertical rule, which is the detail that makes the screen read as a
/// table rather than as loose text.
class PropertyRow extends StatelessWidget {
  const PropertyRow({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.onTap,
  });

  final IconData icon;
  final String label;

  /// The value - usually a Text, a badge or a small dropdown.
  final Widget child;
  final VoidCallback? onTap;

  static const double _labelWidth = 116;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _labelWidth,
            child: Row(
              children: [
                Icon(icon, size: 16, color: c.textTertiary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: c.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // The value takes whatever width is left, so long names ellipsise
          // instead of pushing the row off screen.
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: child),
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: row,
    );
  }
}
