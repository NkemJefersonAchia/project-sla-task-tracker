import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// One row in the settings card.
///
/// A null [onTap] renders the row disabled rather than hiding it, so the
/// settings list shows the full shape of the feature even while some of it is
/// still being built. [trailingNote] is where that state is spelled out.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingNote,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? trailingNote;

  /// Suppresses the bottom hairline so the last row sits flush with the card.
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = onTap != null;
    final foreground = enabled ? c.textPrimary : c.textTertiary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: enabled ? c.textSecondary : c.textTertiary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(color: foreground),
              ),
            ),
            if (trailingNote != null) ...[
              Text(
                trailingNote!,
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: enabled ? c.textTertiary : c.border,
            ),
          ],
        ),
      ),
    );
  }
}
