import 'package:flutter/material.dart';

import '../../services/storage_service.dart';

/// Holds the app-wide light/dark preference.
///
/// A [ValueNotifier] rather than `setState`, because the value is read at the
/// very top of the tree (`MaterialApp`) but changed from deep inside the
/// profile screen. `setState` cannot cross that distance; a notifier plus one
/// [ValueListenableBuilder] can, without pulling in a state-management
/// package. Everything else in the app still uses plain `setState`.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);

  static final ThemeController instance = ThemeController._();

  /// Restores the saved preference. Called once at start-up, before the first
  /// frame, so the app never flashes the wrong theme.
  Future<void> load() async {
    final stored = StorageService.instance.readString(StorageKeys.themeMode);
    value = _fromKey(stored);
  }

  Future<void> setMode(ThemeMode mode) async {
    if (mode == value) return;
    value = mode;
    await StorageService.instance.writeString(
      StorageKeys.themeMode,
      _toKey(mode),
    );
  }

  static ThemeMode _fromKey(String? key) {
    switch (key) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
