import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// An honest placeholder for the parts of the app that are still being built.
///
/// Shipping a visible note is better than shipping a button that silently
/// does nothing: during a review it is obvious what is finished and what is
/// still in progress, and each notice names the work stream that owns it.
class UnbuiltFeatureNotice extends StatelessWidget {
  const UnbuiltFeatureNotice({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.construction_rounded, size: 16, color: c.textTertiary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.caption.copyWith(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTypography.caption.copyWith(color: c.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
