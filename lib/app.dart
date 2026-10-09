import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'repositories/session_repository.dart';

/// The root widget.
///
/// Its only jobs are to supply the theme, install the route table, and say
/// which screen the app opens on. No real work happens here.
class TaskTrackerApp extends StatelessWidget {
  const TaskTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The theme preference is the one value that has to be readable right at
    // the top of the tree but is changed from deep inside the Profile tab.
    // `setState` cannot reach that far, so it is the one listenable we use.
    // Everything else in the app is plain `setState`.
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
          initialRoute: SessionRepository.instance.isSignedIn
              ? AppRoutes.home
              : AppRoutes.login,
        );
      },
    );
  }
}