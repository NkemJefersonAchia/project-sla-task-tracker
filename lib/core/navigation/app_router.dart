import 'package:flutter/material.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/sign_up_screen.dart';
import '../../screens/home_shell.dart';
import '../../screens/stats/task_statistics_screen.dart';
import '../../screens/team/member_form_screen.dart';
import '../../screens/tasks/task_detail_screen.dart';
import '../../screens/tasks/task_form_screen.dart';
import '../constants/app_routes.dart';

/// Turns a route name into a screen.
///
/// The app uses named routes through `onGenerateRoute` rather than
/// `MaterialApp.routes`, because screens that take arguments need somewhere to
/// unpack them once, in one place, instead of casting in three widgets.
///
/// ## Adding a route
///
/// Add a `case` for your name from [AppRoutes] and return `_page(...)`. If
/// your screen passes data, pass only an **id** - never the whole object - and
/// let the destination look it up from its repository. A screen that holds a
/// copy of a task will happily show a stale one after somebody edits it
/// elsewhere.
abstract final class AppRouter {
  static Route<Object?> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _page<Object?>(const HomeShell(), settings);

      case AppRoutes.login:
        return _page<Object?>(const LoginScreen(), settings);

      case AppRoutes.signUp:
        return _page<Object?>(const SignUpScreen(), settings);

      case AppRoutes.statistics:
        return _page<Object?>(const TaskStatisticsScreen(), settings);

      case AppRoutes.memberForm:
        // The id arrives as a bare String? - null means "create".
        final memberId = settings.arguments as String?;
        // Pops `true` when the member was saved.
        return _page<bool>(MemberFormScreen(memberId: memberId), settings);

      case AppRoutes.taskDetail:
        final args = _requireArgs<TaskDetailArgs>(settings);
        // Pops `true` when the task was deleted, so the list behind re-reads.
        return _page<bool>(TaskDetailScreen(taskId: args.taskId), settings);

      case AppRoutes.taskForm:
        final args = _requireArgs<TaskFormArgs>(settings);
        // Pops `true` when a task was created or updated.
        return _page<bool>(
          TaskFormScreen(taskId: args.taskId),
          settings,
          // Arrives from the bottom with a close button rather than a back
          // arrow: this is a job you either finish or abandon, not a place
          // you browse to.
          fullscreenDialog: true,
        );

      default:
        return _page<Object?>(
          _UnknownRouteScreen(name: settings.name),
          settings,
        );
    }
  }

  /// Unpacks a route's arguments and fails loudly during development if a
  /// screen was pushed without what it needs - better than a null blowing up
  /// three widgets deeper with no mention of the route that caused it.
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

  static MaterialPageRoute<T> _page<T>(
    Widget child,
    RouteSettings settings, {
    bool fullscreenDialog = false,
  }) {
    return MaterialPageRoute<T>(
      builder: (_) => child,
      // Passing settings through keeps the route's name attached, which is
      // what `popUntil(ModalRoute.withName(...))` needs to work.
      settings: settings,
      fullscreenDialog: fullscreenDialog,
    );
  }
}

/// Shown if a route name is ever mistyped - a readable screen with a way back
/// beats a blank black page.
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