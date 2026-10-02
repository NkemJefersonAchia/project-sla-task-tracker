import 'package:flutter/material.dart';

import 'core/constants/app_routes.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';

/// The root widget.
///
/// Its only jobs are to supply the theme, install the route table, and say
/// which screen the app opens on. No real work happens here.
///
/// ## For whoever builds the welcome / sign-in screen
///
/// Right now the app opens straight onto the tabs. When your screen exists,
/// this is where you decide between them: send a returning user to
/// [AppRoutes.home] and everybody else to your screen. `SessionRepository`
/// already remembers who signed in last and survives a restart, so that check
/// is a plain synchronous read - you do not need a loading screen for it.
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
          initialRoute: AppRoutes.home,
        );
      },
    );
  }
}
