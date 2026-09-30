import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Builds the light and dark [ThemeData] from our tokens.
///
/// Everything that Flutter's own widgets read (AppBar, TextField, Dialog,
/// SnackBar…) is configured once here, so individual screens stay free of
/// styling noise and the whole app stays visually consistent.
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      dividerColor: c.border,
      colorScheme: base.colorScheme.copyWith(
        primary: c.accent,
        onPrimary: c.canvas,
        surface: c.surface,
        onSurface: c.textPrimary,
        error: c.red,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionTitle.copyWith(
          color: c.textPrimary,
        ),
        iconTheme: IconThemeData(color: c.textSecondary, size: 20),
      ),
      dividerTheme: DividerThemeData(
        color: c.border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: c.textSecondary, size: 20),
      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        horizontalTitleGap: AppSpacing.md,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceMuted,
        hintStyle: AppTypography.body.copyWith(color: c.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: _inputBorder(c.border),
        enabledBorder: _inputBorder(c.border),
        focusedBorder: _inputBorder(c.borderStrong),
        errorBorder: _inputBorder(c.red),
        focusedErrorBorder: _inputBorder(c.red),
        errorStyle: AppTypography.caption.copyWith(color: c.red),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark
            ? c.surfaceMuted
            : const Color(0xFF2F2F2F),
        contentTextStyle: AppTypography.caption.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTypography.sectionTitle.copyWith(
          color: c.textPrimary,
        ),
        contentTextStyle: AppTypography.body.copyWith(color: c.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
      highlightColor: c.hover,
    );
  }

  static OutlineInputBorder _inputBorder(Color color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color),
      );
}
