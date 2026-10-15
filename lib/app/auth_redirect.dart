import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/app/app_routes.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';

/// Decides where to send the user based on auth state. Pure, so it is easy
/// to unit test. Returns null to stay on [uri].
///
/// When a signed-out user opens a protected location (e.g. a deep link), it
/// is kept in `?from=` and restored after sign-in, unless
/// [rememberLocation] is false (used right after the user signs out, so the
/// next sign-in starts at the Dashboard).
String? authRedirect({
  required AsyncValue<AppUser?> authState,
  required Uri uri,
  bool rememberLocation = true,
}) {
  final path = uri.path;
  final isDefault =
      path == AppRoutes.defaultLocation && !uri.hasQuery && !uri.hasFragment;

  // Auth state not known yet (first event from Firebase pending). Keep the
  // requested location (e.g. a cold-start deep link) in `?from=` so it can be
  // restored once auth resolves.
  if (authState.isLoading && !authState.hasValue) {
    if (path == AppRoutes.splash) return null;
    final keep = !isDefault && !AppRoutes.signedOutOnly.contains(path);
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
    final from = !rememberLocation || isDefault
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
    return safe ? from : AppRoutes.defaultLocation;
  }
  return null;
}
