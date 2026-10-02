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
/// frame. That is a deliberate trade: a few milliseconds of start-up time buys
/// screens that can read their data synchronously, so no tab has to render a
/// spinner or flash an empty list on the way in.
///
/// What that means for you: inside your `build` method,
/// `TaskRepository.instance.all` is just there. No `FutureBuilder`, no
/// `async`. Read it straight.
Future<void> main() async {
  // Required before touching any plugin - SharedPreferences, here - ahead of
  // runApp.
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await StorageService.instance.init();
    await ThemeController.instance.load();

    // Members load first: the session turns a stored member id back into a
    // person, and tasks are displayed with their assignee's name.
    await MemberRepository.instance.load();
    await TaskRepository.instance.load();
    await SessionRepository.instance.load();

    await _signInDefaultUserUntilWelcomeScreenExists();
  } catch (error) {
    // If storage cannot be opened there is no app to show, so fail with a
    // readable screen rather than a blank one.
    runApp(_StartupFailureApp(error: error));
    return;
  }

  runApp(const TaskTrackerApp());
}

/// Temporary: picks the first team member so the app always has a current
/// user.
///
/// The Profile tab needs to know who "you" are, and until the welcome screen
/// exists there is nothing to ask. This keeps the other three tabs unblocked.
///
/// **Delete this whole function** when the welcome / sign-in screen lands -
/// choosing the user is that screen's entire job.
Future<void> _signInDefaultUserUntilWelcomeScreenExists() async {
  if (SessionRepository.instance.isSignedIn) return;

  final members = MemberRepository.instance.all;
  if (members.isEmpty) return;

  await SessionRepository.instance.signIn(members.first);
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
