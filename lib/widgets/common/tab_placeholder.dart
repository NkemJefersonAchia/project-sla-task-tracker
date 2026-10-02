import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Stands in for a tab that has not been built yet.
///
/// Every tab starts as one of these so the app runs from day one and nobody is
/// blocked waiting for somebody else's screen. Delete your tab's placeholder as
/// soon as you have something real to put there - it is not meant to survive
/// into the finished app.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({
    super.key,
    required this.tab,
    required this.owner,
    required this.summary,
    required this.buildThis,
  });

  /// The tab's name, e.g. "Home".
  final String tab;

  /// The branch whoever owns this tab works on.
  final String owner;

  /// One sentence on what the finished tab is for.
  final String summary;

  /// The pieces that have to exist before this tab counts as done.
  final List<String> buildThis;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(
                Icons.add_rounded,
                size: 20,
                color: c.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '$tab is empty',
              style: AppTypography.pageTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              summary,
              style: AppTypography.body.copyWith(color: c.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'TO BUILD',
              style: AppTypography.overline.copyWith(color: c.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in buildThis)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        height: 4,
                        width: 4,
                        decoration: BoxDecoration(
                          color: c.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        item,
                        style: AppTypography.caption.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                'Branch: $owner',
                style: AppTypography.caption.copyWith(color: c.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
