import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/destination_scope.dart';
import 'package:mfb_think_tank/app/feature_heading.dart';
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/features/dashboard/application/dashboard_revision_provider.dart';
import 'package:mfb_think_tank/features/dashboard/data/dashboard_policy.dart';
import 'package:mfb_think_tank/features/dashboard/presentation/dashboard_webview.dart';
import 'package:mfb_think_tank/features/readers_digest/application/app_lifecycle_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/feed_message.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The complete Crucix dashboard inside native app chrome.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({this.query = '', super.key});
  final String query;
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  Uri? _resume;
  double _scroll = 0;
  int _revision = 0;
  String? _uid;

  @override
  void didUpdateWidget(DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _resume = null;
      _scroll = 0;
      _revision++;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    final accountRevision = ref.watch(dashboardRevisionProvider);
    if (uid != _uid) {
      _uid = uid;
      _resume = null;
      _scroll = 0;
    }
    final active =
        DestinationScope.isActive(context, 0) &&
        ref.watch(appLifecycleProvider) == AppLifecycleState.resumed;
    final base = Uri.tryParse(ref.watch(appConfigProvider).crucixApiBaseUrl);
    DashboardPolicy? policy;
    try {
      if (base != null) policy = DashboardPolicy(base);
    } on ArgumentError {
      /* Shown below. */
    }
    return Column(
      children: [
        FeatureHeading(
          title: 'Dashboard',
          subtitle: 'Your global intelligence picture.',
          trailing: IconButton(
            key: const Key('dashboard-refresh'),
            tooltip: 'Refresh dashboard',
            onPressed: () => setState(() => _revision++),
            icon: const Icon(Icons.refresh),
          ),
        ),
        Expanded(
          child: policy == null || WebViewPlatform.instance == null
              ? const SingleChildScrollView(
                  child: FeedMessage(
                    title: 'Dashboard needs the mobile browser',
                    body: 'Open this destination on Android or iOS with a configured intelligence server.',
                  ),
                )
              : !active || uid == null
              ? const SizedBox.shrink()
              : DashboardWebview(
                  key: ValueKey('$uid:$_revision:$accountRevision'),
                  policy: policy,
                  resume:
                      _resume ??
                      policy.base.replace(
                        path: '/',
                        query: widget.query.isEmpty ? null : widget.query,
                      ),
                  scroll: _scroll,
                  onLocation: (uri, scroll) {
                    _resume = uri;
                    _scroll = scroll;
                  },
                  onRetry: () => setState(() => _revision++),
                ),
        ),
      ],
    );
  }
}
