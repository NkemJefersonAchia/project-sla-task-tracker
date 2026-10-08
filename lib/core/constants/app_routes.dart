/// Every named route in the app.
///
/// Constants instead of raw strings, so a typo is a compile error rather than
/// a blank screen at runtime, and so this file is a list of everywhere the app
/// can go.
///
/// ## Adding your own routes
///
/// Add the name here, then handle it in `core/navigation/app_router.dart`.
/// Both files are shared, so do it in one small commit early and push it -
/// that way nobody is editing the same lines as you a week later.
///
/// If your screen returns something when it closes - a form that pops `true`
/// after saving, say - build it as `Route<bool>` in the router. `pushNamed<T>`
/// casts the route it gets back, and a mismatch throws at runtime.
abstract final class AppRoutes {
  /// The shell that holds the four bottom-navigation tabs.
  static const String home = '/';

  /// Sign-in and account creation.
  static const String login = '/login';
  static const String signUp = '/sign-up';

  // The task detail and task form routes go here.
}