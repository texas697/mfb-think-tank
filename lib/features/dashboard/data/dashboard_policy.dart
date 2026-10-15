import 'package:mfb_think_tank/app/app_routes.dart';

/// Exact-origin browser boundary and mapping from web to native destinations.
class DashboardPolicy {
  DashboardPolicy(this.base) {
    if (base.scheme != 'https' &&
        !(base.scheme == 'http' &&
            const {'localhost', '127.0.0.1', '10.0.2.2'}.contains(base.host))) {
      throw ArgumentError('Dashboard requires HTTPS');
    }
    if (base.userInfo.isNotEmpty || base.host.isEmpty) {
      throw ArgumentError('Invalid origin');
    }
  }

  final Uri base;

  bool isTrusted(Uri uri) =>
      uri.hasAuthority &&
      const {'http', 'https'}.contains(uri.scheme) &&
      uri.origin == base.origin &&
      uri.userInfo.isEmpty;
  bool isDashboard(Uri uri) => isTrusted(uri) && uri.path == '/';
  bool isLogin(Uri uri) => isTrusted(uri) && uri.path == '/login';

  String? nativeLocation(Uri uri) {
    if (!isTrusted(uri)) return null;
    final parts = uri.pathSegments;
    if (parts.isEmpty || parts.length > 2) return null;
    final rest = parts.length == 2 ? parts[1] : null;
    return switch (parts.first) {
      'digest' =>
        rest == null
            ? Uri(
                path: AppRoutes.home,
                query: uri.hasQuery ? uri.query : null,
              ).toString()
            : AppRoutes.articleLocation(rest),
      'media' => Uri(
        path: rest == null ? AppRoutes.media : AppRoutes.mediaLocation(rest),
        query: uri.hasQuery ? uri.query : null,
      ).toString(),
      'telegram' =>
        rest == null ? AppRoutes.telegram : AppRoutes.telegramLocation(rest),
      _ => null,
    };
  }
}
