import 'package:mfb_think_tank/features/dashboard/data/dashboard_policy.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Keeps browser navigation on the dashboard’s trusted main document.
NavigationDecision dashboardNavigationDecision(
  NavigationRequest request,
  DashboardPolicy policy, {
  required void Function(String) onNative,
  required void Function(Uri) onExternal,
}) {
  if (!request.isMainFrame) return NavigationDecision.navigate;
  final uri = Uri.tryParse(request.url);
  if (uri == null) return NavigationDecision.prevent;
  if (uri.toString() == 'about:blank' ||
      policy.isDashboard(uri) ||
      policy.isLogin(uri)) {
    return NavigationDecision.navigate;
  }
  final native = policy.nativeLocation(uri);
  if (native != null) {
    onNative(native);
  } else if (!policy.isTrusted(uri) &&
      const {'https', 'http'}.contains(uri.scheme) &&
      uri.hasAuthority) {
    onExternal(uri);
  }
  return NavigationDecision.prevent;
}
