import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mfb_think_tank/app/app_routes.dart';
import 'package:mfb_think_tank/app/auth_redirect.dart';
import 'package:mfb_think_tank/app/shell_routes.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/presentation/forgot_password_screen.dart';
import 'package:mfb_think_tank/features/auth/presentation/sign_in_screen.dart';
import 'package:mfb_think_tank/features/auth/presentation/sign_up_screen.dart';
import 'package:mfb_think_tank/features/auth/presentation/splash_screen.dart';

export 'app_routes.dart';
export 'auth_redirect.dart';

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

  final rootNavigatorKey = GlobalKey<NavigatorState>();
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
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
      buildShellRoute(rootNavigatorKey),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
