import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// One entry point for transient user feedback.
///
/// Having a single helper means every confirmation and every error in the app
/// looks the same and none of them is accidentally left out - a screen that
/// saves data always calls [showSuccess] or [showError] on the way out.
abstract final class AppFeedback {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, Icons.check_rounded, null);
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Icons.error_outline_rounded,
        AppColors.of(context).red);
  }

  static void _show(
    BuildContext context,
    String message,
    IconData icon,
    Color? iconColor,
  ) {
    final messenger = ScaffoldMessenger.of(context);
    // Replace whatever is on screen so rapid actions do not queue up a stack
    // of snack bars the user has to sit through.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, size: 16, color: iconColor ?? Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  /// Modal yes/no gate for destructive actions such as deleting a task.
  /// Returns true only when the user explicitly confirms.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    bool destructive = true,
  }) async {
    final c = AppColors.of(context);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(foregroundColor: c.textSecondary),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: destructive ? c.red : c.textPrimary,
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}
