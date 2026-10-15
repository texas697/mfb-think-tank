import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/feed_message.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Hides login/bootstrap and presents bounded, recoverable loading failures.
class DashboardBrowserBody extends StatelessWidget {
  const DashboardBrowserBody({
    required this.browser,
    required this.isReady,
    required this.error,
    required this.onRetry,
    super.key,
  });
  final WebViewController? browser;
  final bool isReady;
  final String? error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return SingleChildScrollView(
        child: FeedMessage(
          title: 'Dashboard unavailable',
          body: error,
          actionLabel: 'Retry',
          onAction: onRetry,
        ),
      );
    }
    return Stack(
      children: [
        if (browser case final value?) WebViewWidget(controller: value),
        if (!isReady)
          const Positioned.fill(
            child: ColoredBox(
              color: AppTheme.background,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
