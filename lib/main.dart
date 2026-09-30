import 'package:flutter/material.dart';

import 'app.dart';
import 'core/theme/theme_controller.dart';
import 'repositories/member_repository.dart';
import 'repositories/session_repository.dart';
import 'repositories/task_repository.dart';
import 'services/storage_service.dart';

/// Application entry point.
///
/// Local storage is opened and every repository is filled *before* the first
/// frame. That is a deliberate trade: a few milliseconds of extra start-up
/// time buys us screens that read their data synchronously, so no list in the
/// app has to render a spinner or an empty flash on the way in.
Future<void> main() async {
  // Required before touching any plugin (SharedPreferences) ahead of runApp.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await StorageService.instance.init();
    await ThemeController.instance.load();

    // Members load first: the session resolves a member id into a person, and
    // tasks are displayed with their assignee's name.
    await MemberRepository.instance.load();
    await TaskRepository.instance.load();
    await SessionRepository.instance.load();
  } catch (error) {
    // If storage cannot be opened at all there is no app to show, so we fail
    // with a readable screen instead of a blank one.
    runApp(_StartupFailureApp(error: error));
    return;
  }

  runApp(const TaskTrackerApp());
}

/// Last-resort screen shown when start-up itself fails.
class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 32),
                const SizedBox(height: 16),
                const Text(
                  'The app could not start',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
