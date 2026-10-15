import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/auth/application/api_client_providers.dart';
import 'package:mfb_think_tank/features/dashboard/application/browser_cleanup.dart';
import 'package:mfb_think_tank/features/dashboard/application/dashboard_session.dart';
import 'package:mfb_think_tank/features/dashboard/data/dashboard_policy.dart';
import 'package:mfb_think_tank/features/dashboard/data/webview_browser_port.dart';
import 'package:mfb_think_tank/features/dashboard/presentation/dashboard_browser_body.dart';
import 'package:mfb_think_tank/features/dashboard/presentation/dashboard_navigation_decision.dart';
import 'package:mfb_think_tank/features/digest_settings/application/me_profile_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/open_external_link.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A trusted browser with native loading/error presentation and session bridging.
class DashboardWebview extends ConsumerStatefulWidget {
  const DashboardWebview({
    required this.policy,
    required this.onLocation,
    required this.onRetry,
    this.resume,
    this.scroll = 0,
    super.key,
  });
  final DashboardPolicy policy;
  final Uri? resume;
  final double scroll;
  final void Function(Uri, double) onLocation;
  final VoidCallback onRetry;

  @override
  ConsumerState<DashboardWebview> createState() => _DashboardWebviewState();
}

class _DashboardWebviewState extends ConsumerState<DashboardWebview> {
  WebViewController? _browser;
  DashboardSession? _session;
  bool _hasFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final script = await rootBundle.loadString('assets/dashboard/embed.js');
      if (!mounted) return;
      final browser = WebviewBrowserPort.createController();
      _browser = browser;
      final tokens = ref.read(idTokenProvider);
      final session = DashboardSession(
        browser: WebviewBrowserPort(browser),
        policy: widget.policy,
        getToken: (force) => tokens.getIdToken(forceRefresh: force),
        embedScript: script,
        resume: widget.resume,
        scroll: widget.scroll,
        onLocation: widget.onLocation,
        onProfileChanged: () {
          if (mounted) ref.invalidate(meProfileProvider);
        },
        onNavigate: (location) {
          if (mounted) context.go(location);
        },
        onExternal: (uri) {
          if (mounted) openExternalLink(context, ref, uri.toString());
        },
      );
      _session = session;
      session.addListener(_changed);
      await browser.setJavaScriptMode(JavaScriptMode.unrestricted);
      await browser.setBackgroundColor(AppTheme.background);
      await browser.addJavaScriptChannel(
        'MfbDashboard',
        onMessageReceived: (m) => session.message(m.message),
      );
      await browser.setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: session.pageFinished,
          onWebResourceError: (e) {
            if (e.isForMainFrame == true) session.fail();
          },
          onNavigationRequest: _navigate,
        ),
      );
      await BrowserCleanup.run(() async {
        await WebViewCookieManager().clearCookies();
        await browser.clearLocalStorage();
      });
      if (!mounted) return;
      setState(() {});
      await session.start();
    } catch (_) {
      if (mounted) setState(() => _hasFailed = true);
    }
  }

  NavigationDecision _navigate(NavigationRequest request) =>
      dashboardNavigationDecision(
        request,
        widget.policy,
        onNative: (location) {
          if (mounted) context.go(location);
        },
        onExternal: (uri) {
          if (mounted) openExternalLink(context, ref, uri.toString());
        },
      );

  void _changed() {
    if (_session?.error != null && !_hasFailed) {
      _hasFailed = true;
      unawaited(
        _browser
                ?.loadRequest(Uri.parse('about:blank'))
                .catchError((Object _) {}) ??
            Future.value(),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _session?.removeListener(_changed);
    _session?.dispose();
    final browser = _browser;
    if (browser != null) {
      unawaited(
        BrowserCleanup.run(() async {
          await browser.clearLocalStorage();
          await WebViewCookieManager().clearCookies();
          await browser.loadRequest(Uri.parse('about:blank'));
        }).catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardBrowserBody(
      browser: _browser,
      isReady: _session?.isReady == true,
      error:
          _session?.error ??
          (_hasFailed ? 'Check your connection and try again.' : null),
      onRetry: widget.onRetry,
    );
  }
}
