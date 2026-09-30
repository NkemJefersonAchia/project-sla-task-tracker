import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Thrown when reading or writing local storage fails.
///
/// Repositories let this bubble up so the UI can show a real message instead
/// of failing silently.
class StorageException implements Exception {
  const StorageException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'StorageException: $message';
}

/// Thin wrapper around `SharedPreferences`.
///
/// ## Why SharedPreferences and not sqflite
///
/// The app stores two small collections (tasks and team members) that are
/// always read in full and never queried relationally - the dashboard, the
/// list and the statistics screen all start from "give me every task" and
/// filter in Dart. A key-value store holding two JSON documents does that in
/// one read, with no schema, no migrations and no platform plugin to set up
/// for the web/desktop targets we use while developing. sqflite would only
/// start to pay off once we need indexed queries or thousands of rows.
///
/// Everything funnels through this one class so that swapping the backing
/// store later means rewriting this file and nothing else.
class StorageService {
  StorageService._();

  /// Single shared instance - local storage is a process-wide resource, so
  /// there is no reason for each repository to hold its own handle.
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  /// Must be awaited once during app start-up (see `main.dart`) so that every
  /// later read is synchronous and the first frame never shows stale data.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (error) {
      throw StorageException('Could not open local storage.', error);
    }
  }

  SharedPreferences get _requirePrefs {
    final prefs = _prefs;
    if (prefs == null) {
      throw const StorageException(
        'StorageService.init() must be called before using storage.',
      );
    }
    return prefs;
  }

  /// True once a given key has ever been written - used to decide whether this
  /// is a first launch that needs seeding.
  bool containsKey(String key) => _requirePrefs.containsKey(key);

  /// Reads a JSON array stored under [key].
  ///
  /// A missing key returns an empty list. A *corrupt* value also returns an
  /// empty list rather than throwing, so a bad write in a previous version can
  /// never permanently brick the app.
  List<Map<String, dynamic>> readJsonList(String key) {
    final raw = _requirePrefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded.whereType<Map<String, dynamic>>().toList();
    } on FormatException {
      return const [];
    }
  }

  /// Serialises [values] to JSON and writes it under [key].
  Future<void> writeJsonList(
    String key,
    List<Map<String, dynamic>> values,
  ) async {
    try {
      await _requirePrefs.setString(key, jsonEncode(values));
    } catch (error) {
      throw StorageException('Could not save data to local storage.', error);
    }
  }

  String? readString(String key) => _requirePrefs.getString(key);

  Future<void> writeString(String key, String value) async {
    try {
      await _requirePrefs.setString(key, value);
    } catch (error) {
      throw StorageException('Could not save data to local storage.', error);
    }
  }

  Future<void> remove(String key) async {
    try {
      await _requirePrefs.remove(key);
    } catch (error) {
      throw StorageException('Could not clear local storage.', error);
    }
  }
}

/// Every key written to local storage, in one place, so it is impossible for
/// two features to collide on the same string.
abstract final class StorageKeys {
  static const String tasks = 'sla_tracker.tasks.v1';
  static const String members = 'sla_tracker.members.v1';
  static const String currentUserId = 'sla_tracker.session.current_user_id';
  static const String themeMode = 'sla_tracker.settings.theme_mode';
}
