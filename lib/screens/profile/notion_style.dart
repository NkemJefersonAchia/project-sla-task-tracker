import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Notion-like palette: neutral greys, one blue accent, one red for danger.
class NotionColors {
  static const background = Colors.white;
  static const text = Color(0xFF37352F);
  static const textSecondary = Color(0xFF787774);
  static const divider = Color(0xFFE9E9E7);
  static const hover = Color(0xFFF7F6F3);
  static const avatarBg = Color(0xFFF1F1EF);
  static const accent = Color(0xFF2383E2);
  static const danger = Color(0xFFEB5757);
}

class NotionText {
  static const pageTitle = TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
  static const subtitle = TextStyle(fontSize: 14);
  static const section = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 15);
}

AppBar notionAppBar(BuildContext context, {String? title}) {
  final c = AppColors.of(context);
  return AppBar(
    backgroundColor: c.canvas,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: c.textPrimary),
    title: title == null
        ? null
        : Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
  );
}
