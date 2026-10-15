import 'package:mfb_think_tank/features/dashboard/data/dashboard_browser_port.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// System browser controller operations for the session state machine.
class WebviewBrowserPort implements DashboardBrowserPort {
  WebviewBrowserPort(this.controller);
  final WebViewController controller;

  /// Enables inline WebKit media while using default system settings elsewhere.
  static WebViewController createController() {
    final params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true)
        : const PlatformWebViewControllerCreationParams();
    return WebViewController.fromPlatformCreationParams(params);
  }

  @override
  Future<void> load(Uri uri) => controller.loadRequest(uri);
  @override
  Future<Uri?> currentUri() async {
    final url = await controller.currentUrl();
    return url == null ? null : Uri.tryParse(url);
  }

  @override
  Future<void> execute(String script) => controller.runJavaScript(script);
}
