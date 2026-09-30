import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'repositories/session_repository.dart';

/// The root widget.
///
/// Its only jobs are to supply the theme, install the route table, and decide
/// which screen the app opens on. All real work lives in the screens.
class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The theme preference is the one value that must be readable from the
    // very top of the tree, so it is the one thing wired with a listenable.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'SLA Task Tracker',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          onGenerateRoute: AppRouter.onGenerateRoute,
          // A returning user who signed in before goes straight to the
          // dashboard; everyone else starts at sign-in. The session was
          // already restored from storage in main(), so this is a plain
          // synchronous read - no loading screen needed.
          initialRoute: SessionRepository.instance.isSignedIn
              ? AppRoutes.home
              : AppRoutes.signIn,
        );
      },
    );
  }
}
