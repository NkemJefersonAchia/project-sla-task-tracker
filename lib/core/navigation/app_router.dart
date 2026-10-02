import 'package:flutter/material.dart';

import '../../screens/home_shell.dart';
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
