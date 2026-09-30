import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The container every block of content sits in.
///
/// Notion's surfaces are defined by a 1px hairline and generous padding rather
/// than by drop shadows, so this is a [Container] with a border - no
/// [Material] elevation anywhere. When [onTap] is supplied the card becomes
/// tappable and gets an ink response, which is how task rows work.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.onLongPress,
    this.background,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final radius = BorderRadius.circular(AppRadius.lg);

    final decorated = Container(
      decoration: BoxDecoration(
        color: background ?? c.surface,
        borderRadius: radius,
        border: Border.all(color: borderColor ?? c.border),
      ),
      // `clipBehavior` keeps the ink splash inside the rounded corners.
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          // A null onTap leaves InkWell inert, so a static card costs nothing.
          splashColor: onTap == null ? Colors.transparent : null,
          highlightColor: c.hover,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    return decorated;
  }
}
