import 'package:flutter/material.dart';

/// Type scale.
///
/// We deliberately use the platform's own UI font (SF on iOS, Roboto on
/// Android) rather than downloading a webfont: it keeps the app working
/// offline and makes text render natively on both platforms. The Notion feel
/// comes from the weights, sizes and tight letter-spacing below.
abstract final class AppTypography {
  static const TextStyle pageTitle = TextStyle(
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  /// Small upper-case label that introduces a group of rows.
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.1,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.05,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.05,
  );

  /// Large numeral used on the dashboard metric tiles.
  static const TextStyle metric = TextStyle(
    fontSize: 26,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
  );
}
