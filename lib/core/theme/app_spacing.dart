/// Spacing and radius scale.
///
/// Every gap in the UI is one of these values. Keeping the scale small is what
/// makes the screens feel like one product instead of six separate ones.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Horizontal padding applied to the body of every screen.
  static const double screenPadding = 20;
}

/// Corner radii. Notion keeps corners tight, so nothing goes above [lg].
abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 6;
  static const double lg = 10;
  static const double pill = 999;
}
