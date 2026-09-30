import 'package:flutter/material.dart';

/// Semantic colour palette for the app.
///
/// The values are a Notion-inspired set: a near-white canvas, low-contrast
/// hairline borders and muted accent colours that are used as a *pair*
/// (a readable foreground colour + a very light tinted background) so badges
/// and chips never shout at the reader.
///
/// Usage: `final c = AppColors.of(context);` then `c.textPrimary`, `c.green`…
/// Resolving through `of(context)` means every widget automatically picks the
/// light or dark variant, so we never hard-code a hex value inside a screen.
@immutable
class AppColors {
  const AppColors._({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.hover,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.accent,
    required this.gray,
    required this.grayBg,
    required this.blue,
    required this.blueBg,
    required this.green,
    required this.greenBg,
    required this.yellow,
    required this.yellowBg,
    required this.red,
    required this.redBg,
    required this.purple,
    required this.purpleBg,
    required this.orange,
    required this.orangeBg,
  });

  /// Page background.
  final Color canvas;

  /// Card / sheet background that sits on top of [canvas].
  final Color surface;

  /// Slightly recessed surface, used for input fields and inline code blocks.
  final Color surfaceMuted;

  /// 1px hairline used for card outlines and dividers.
  final Color border;

  /// Stronger hairline for focused inputs.
  final Color borderStrong;

  /// Pressed / selected row background.
  final Color hover;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;

  /// The single brand accent, used for primary buttons and the active nav item.
  final Color accent;

  // Accent pairs: `x` is the foreground, `xBg` the matching tinted background.
  final Color gray;
  final Color grayBg;
  final Color blue;
  final Color blueBg;
  final Color green;
  final Color greenBg;
  final Color yellow;
  final Color yellowBg;
  final Color red;
  final Color redBg;
  final Color purple;
  final Color purpleBg;
  final Color orange;
  final Color orangeBg;

  static const AppColors light = AppColors._(
    canvas: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF7F7F5),
    border: Color(0xFFE9E9E7),
    borderStrong: Color(0xFFD3D1CB),
    hover: Color(0xFFF1F1EF),
    textPrimary: Color(0xFF37352F),
    textSecondary: Color(0xFF787774),
    textTertiary: Color(0xFF9B9A97),
    accent: Color(0xFF37352F),
    gray: Color(0xFF787774),
    grayBg: Color(0xFFF1F1EF),
    blue: Color(0xFF337EA9),
    blueBg: Color(0xFFE7F3F8),
    green: Color(0xFF448361),
    greenBg: Color(0xFFEDF3EC),
    yellow: Color(0xFFCB912F),
    yellowBg: Color(0xFFFBF3DB),
    red: Color(0xFFD44C47),
    redBg: Color(0xFFFDEBEC),
    purple: Color(0xFF9065B0),
    purpleBg: Color(0xFFF6F3F9),
    orange: Color(0xFFD9730D),
    orangeBg: Color(0xFFFAEBDD),
  );

  static const AppColors dark = AppColors._(
    canvas: Color(0xFF191919),
    surface: Color(0xFF202020),
    surfaceMuted: Color(0xFF252525),
    border: Color(0xFF2F2F2F),
    borderStrong: Color(0xFF474747),
    hover: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFD4D4D4),
    textSecondary: Color(0xFF9B9B9B),
    textTertiary: Color(0xFF6F6F6F),
    accent: Color(0xFFD4D4D4),
    gray: Color(0xFF979A9B),
    grayBg: Color(0xFF2F2F2F),
    blue: Color(0xFF5E87C9),
    blueBg: Color(0xFF1F282D),
    green: Color(0xFF529E72),
    greenBg: Color(0xFF242B26),
    yellow: Color(0xFFCA9849),
    yellowBg: Color(0xFF372E20),
    red: Color(0xFFDF5452),
    redBg: Color(0xFF332523),
    purple: Color(0xFF9A6DD7),
    purpleBg: Color(0xFF2A2430),
    orange: Color(0xFFC77D48),
    orangeBg: Color(0xFF36291F),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
