import 'package:mfb_think_tank/features/dashboard/data/dashboard_policy.dart';

/// Safe native navigation and location reports from the owned browser bridge.
class DashboardNavigation {
  DashboardNavigation({
    required this.policy,
    required this.onLocation,
    required this.onNavigate,
    required this.onExternal,
  });
  final DashboardPolicy policy;
  final void Function(Uri, double) onLocation;
  final void Function(String) onNavigate;
  final void Function(Uri) onExternal;

  void handle(Map<String, dynamic> message) {
    final uri = Uri.tryParse(message['url'] as String? ?? '');
    if (uri == null) return;
    if (message['type'] == 'location' && policy.isDashboard(uri)) {
      final offset = (message['scroll'] as num?)?.toDouble() ?? 0;
      onLocation(uri, offset.isFinite ? offset.clamp(0, 100000) : 0);
    } else if (message['type'] == 'navigate') {
      final native = policy.nativeLocation(uri);
      if (native != null) {
        onNavigate(native);
      } else if (!policy.isTrusted(uri) &&
          const {'http', 'https'}.contains(uri.scheme) &&
          uri.hasAuthority) {
        onExternal(uri);
      }
    }
  }
}
