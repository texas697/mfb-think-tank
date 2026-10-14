import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/presentation/forgot_password_screen.dart';
import 'package:mfb_think_tank/features/auth/presentation/sign_in_screen.dart';
import 'package:mfb_think_tank/features/auth/presentation/sign_up_screen.dart';
import 'package:mfb_think_tank/features/auth/presentation/splash_screen.dart';
import 'package:mfb_think_tank/features/profile/presentation/profile_screen.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/article_screen.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_screen.dart';

/// Route paths. Use these instead of string literals.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const forgotPassword = '/forgot-password';
  static const home = '/';
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

/// Decides where to send the user based on auth state. Pure, so it is easy
/// to unit test. Returns null to stay on [uri].
///
/// When a signed-out user opens a protected location (e.g. a deep link), it
/// is kept in `?from=` and restored after sign-in, unless
/// [rememberLocation] is false (used right after the user signs out, so the
/// next sign-in starts at home).
String? authRedirect({
  required AsyncValue<AppUser?> authState,
  required Uri uri,
  bool rememberLocation = true,
}) {
  final path = uri.path;

  // Auth state not known yet (first event from Firebase pending). Keep the
  // requested location (e.g. a cold-start deep link) in `?from=` so it can be
  // restored once auth resolves.
  if (authState.isLoading && !authState.hasValue) {
    if (path == AppRoutes.splash) return null;
    final keep =
        path != AppRoutes.home && !AppRoutes.signedOutOnly.contains(path);
    return Uri(
      path: AppRoutes.splash,
      queryParameters: keep ? {AppRoutes.fromParam: uri.toString()} : null,
    ).toString();
  }

  // An error is treated as signed out.
  final signedIn = authState.value != null;
  final onSignedOutRoute = AppRoutes.signedOutOnly.contains(path);

  if (!signedIn) {
    if (onSignedOutRoute) return null;
    // Remember deep links so the user lands there after signing in.
    // On the splash screen, forward the location kept while loading.
    final from = !rememberLocation || path == AppRoutes.home
        ? null
        : path == AppRoutes.splash
        ? uri.queryParameters[AppRoutes.fromParam]
        : uri.toString();
    return Uri(
      path: AppRoutes.signIn,
      queryParameters: from == null ? null : {AppRoutes.fromParam: from},
    ).toString();
  }

  if (onSignedOutRoute || path == AppRoutes.splash) {
    final from = uri.queryParameters[AppRoutes.fromParam];
    // Only allow app-relative paths to avoid open redirects.
    final safe = from != null && from.startsWith('/') && !from.startsWith('//');
    return safe ? from : AppRoutes.home;
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  // Bridge Riverpod -> Listenable so GoRouter re-runs redirect on auth change
  // without the router itself being rebuilt.
  final authState = ValueNotifier<AsyncValue<AppUser?>>(const AsyncLoading());
  var justSignedOut = false;
  ref
    ..listen(authStateChangesProvider, (previous, next) {
      justSignedOut = previous?.value != null && next.value == null;
      authState.value = next;
    }, fireImmediately: true)
    ..onDispose(authState.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: authState,
    redirect: (context, state) => authRedirect(
      authState: authState.value,
      uri: state.uri,
      rememberLocation: !justSignedOut,
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => DigestScreen(
          query: DigestQuery.sanitized(
            filter: state.uri.queryParameters['filter'] ?? '',
            topic: state.uri.queryParameters['topic'] ?? '',
            q: state.uri.queryParameters['q'] ?? '',
          ),
        ),
        routes: [
          GoRoute(
            path: AppRoutes.article.substring(1),
            builder: (context, state) =>
                ArticleScreen(id: state.pathParameters['id'] ?? ''),
          ),
          GoRoute(
            path: AppRoutes.profile.substring(1),
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
