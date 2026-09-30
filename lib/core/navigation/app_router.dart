import 'package:flutter/material.dart';

import '../../screens/auth/sign_in_screen.dart';
import '../../screens/home_shell.dart';
import '../../screens/stats/task_statistics_screen.dart';
import '../../screens/tasks/task_detail_screen.dart';
import '../../screens/tasks/task_form_screen.dart';
import '../constants/app_routes.dart';

/// Central route table.
///
/// The app uses **named routes with `onGenerateRoute`** rather than
/// `MaterialApp.routes`, because two of our screens need typed arguments. A
/// generator gives us one place to unpack `settings.arguments`, cast it once,
/// and fail loudly during development if a screen is pushed without the
/// arguments it needs - instead of a `null` blowing up three widgets deeper.
abstract final class AppRouter {
  /// Each route is created with the result type its screen actually pops.
  ///
  /// This matters: `Navigator.pushNamed<bool>` casts whatever this factory
  /// returns to `Route<bool?>`, and a `MaterialPageRoute<dynamic>` fails that
  /// cast at runtime. The two screens that report a result back - the task
  /// form and the task detail screen, both of which can pop `true` - are
  /// therefore built as `Route<bool>`; everything else uses `Object?`.
  static Route<Object?> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.signIn:
        return _page<Object?>(const SignInScreen(), settings);

      case AppRoutes.home:
        return _page<Object?>(const HomeShell(), settings);

      case AppRoutes.taskDetail:
        final args = _requireArgs<TaskDetailArgs>(settings);
        // Pops `true` when the task was deleted.
        return _page<bool>(TaskDetailScreen(taskId: args.taskId), settings);

      case AppRoutes.taskForm:
        final args = _requireArgs<TaskFormArgs>(settings);
        // Pops `true` when a task was created or updated.
        return _page<bool>(
          TaskFormScreen(taskId: args.taskId),
          settings,
          // The create/edit form arrives from the bottom: it is a modal task
          // the user either completes or cancels, not a place they browse to.
          fullscreenDialog: true,
        );

      case AppRoutes.statistics:
        return _page<Object?>(const TaskStatisticsScreen(), settings);

      default:
        return _page<Object?>(
          _UnknownRouteScreen(name: settings.name),
          settings,
        );
    }
  }

  static MaterialPageRoute<T> _page<T>(
    Widget child,
    RouteSettings settings, {
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<T>(
      builder: (_) => child,
      // Passing the settings through keeps the route name attached, which is
      // what `popUntil(ModalRoute.withName(...))` relies on.
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }

  static T _requireArgs<T>(RouteSettings settings) {
    final args = settings.arguments;
    if (args is! T) {
      throw ArgumentError(
        'Route ${settings.name} requires arguments of type $T '
        'but received ${args.runtimeType}.',
      );
    }
    return args;
  }
}

/// Shown if a route name is ever mistyped. Better a readable screen with a way
/// back than a blank black page.
class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Text('No route defined for "${name ?? 'unknown'}".'),
      ),
    );
  }
}
