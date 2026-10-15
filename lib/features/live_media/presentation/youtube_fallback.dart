import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/readers_digest/application/app_lifecycle_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/open_external_link.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// In-app YouTube alternative with a system-browser escape hatch.
class YoutubeFallback extends ConsumerStatefulWidget {
  const YoutubeFallback({required this.url, required this.title, super.key});
  final String url;
  final String title;
  @override
  ConsumerState<YoutubeFallback> createState() => _YoutubeFallbackState();
}

class _YoutubeFallbackState extends ConsumerState<YoutubeFallback> {
  WebViewController? _controller;
  @override
  void initState() {
    super.initState();
    if (WebViewPlatform.instance == null) return;
    final id = Uri.parse(widget.url).queryParameters['v'];
    if (id == null || !RegExp(r'^[\w-]{11}$').hasMatch(id)) return;
    final params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true)
        : const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppTheme.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) {
            final uri = Uri.tryParse(r.url);
            if (!r.isMainFrame ||
                (uri?.scheme == 'https' &&
                    uri?.host == 'www.youtube-nocookie.com')) {
              return NavigationDecision.navigate;
            }
            openExternalLink(context, ref, r.url);
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(
        Uri.https('www.youtube-nocookie.com', '/embed/$id', {
          'playsinline': '1',
        }),
      );
  }

  @override
  void dispose() {
    unawaited(
      _controller
              ?.loadRequest(Uri.parse('about:blank'))
              .catchError((Object _) {}) ??
          Future.value(),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLifecycleProvider, (_, next) {
      if (next != AppLifecycleState.resumed) {
        unawaited(
          _controller?.runJavaScript(
                'document.querySelectorAll("video").forEach(v => v.pause());',
              ) ??
              Future.value(),
        );
      }
    });
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _controller == null
                  ? const Center(
                      child: Text('Open the alternative in your browser.'),
                    )
                  : WebViewWidget(controller: _controller!),
            ),
            TextButton.icon(
              onPressed: () => openExternalLink(context, ref, widget.url),
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open YouTube in browser'),
            ),
          ],
        ),
      ),
    );
  }
}
