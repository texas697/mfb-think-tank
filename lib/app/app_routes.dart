/// Route paths. Use these instead of string literals.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const home = '/';
  static const dashboard = '/dashboard';
  static const defaultLocation = dashboard;
  static const media = '/media';
  static const telegram = '/telegram';

  static String mediaLocation(String id) => '/media/${Uri.encodeComponent(id)}';
  static String telegramLocation(String id) =>
      '/telegram/${Uri.encodeComponent(id)}';

  static const profile = '/profile';
  static const article = '/article/:id';

  /// Location of the reader for article [id].
  static String articleLocation(String id) =>
      '/article/${Uri.encodeComponent(id)}';

  /// Routes reachable only while signed out.
  static const signedOutOnly = {signIn, signUp, forgotPassword};

  /// Query parameter carrying the location to return to after sign-in.
  static const fromParam = 'from';
}
