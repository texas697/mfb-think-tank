import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mfb_think_tank/features/dashboard/data/dashboard_browser_port.dart';
import 'package:mfb_think_tank/features/dashboard/data/dashboard_navigation.dart';
import 'package:mfb_think_tank/features/dashboard/data/dashboard_policy.dart';
import 'package:mfb_think_tank/features/dashboard/data/dashboard_scripts.dart';

/// Bounded trusted-origin session exchange; never persists the ID token.
class DashboardSession extends ChangeNotifier {
  DashboardSession({
    required this.browser,
    required this.policy,
    required this.getToken,
    required this.embedScript,
    required void Function(Uri, double) onLocation,
    required void Function(String) onNavigate,
    required void Function(Uri) onExternal,
    String? bridgeNonce,
    this.onProfileChanged,
    this.scroll = 0,
    Uri? resume,
  }) : _nonce =
           bridgeNonce ??
           List.generate(
             24,
             (_) =>
                 Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0'),
           ).join(),
       _navigation = DashboardNavigation(
         policy: policy,
         onLocation: onLocation,
         onNavigate: onNavigate,
         onExternal: onExternal,
       ),
       target = resume != null && policy.isDashboard(resume)
           ? resume
           : policy.base.replace(path: '/');

  final DashboardBrowserPort browser;
  final DashboardPolicy policy;
  final Future<String> Function(bool force) getToken;
  final String embedScript;
  final void Function()? onProfileChanged;
  final String _nonce;
  final DashboardNavigation _navigation;
  final double scroll;
  final Uri target;
  bool isReady = false;
  String? error;
  bool _isDisposed = false;
  bool _isExchanging = false;
  int _exchanges = 0;
  Timer? _deadline;

  Future<void> start() async {
    _deadline?.cancel();
    _deadline = Timer(const Duration(seconds: 35), fail);
    try {
      await browser.load(policy.base.resolve('/login'));
    } catch (_) {
      fail();
    }
  }

  Future<void> pageFinished(String url) async {
    if (_isDisposed || error != null) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !policy.isTrusted(uri)) return;
    try {
      if (policy.isLogin(uri)) {
        if (!_isExchanging) await _exchange();
      } else if (policy.isDashboard(uri)) {
        await browser.execute(DashboardScripts.restore(scroll));
        await browser.execute(
          embedScript.replaceFirst('__MFB_NONCE__', jsonEncode(_nonce)),
        );
      }
    } catch (_) {
      fail();
    }
  }

  Future<void> message(String raw) async {
    if (_isDisposed || error != null) return;
    try {
      final current = await browser.currentUri();
      if (_isDisposed || current == null || !policy.isTrusted(current)) return;
      final msg = jsonDecode(raw) as Map<String, dynamic>;
      if (msg['nonce'] != _nonce) return;
      switch (msg['type']) {
        case 'session':
          if (!_isExchanging || !policy.isLogin(current)) return;
          _isExchanging = false;
          if (msg['ok'] != true) {
            await _exchange();
            return;
          }
          final theme = target.queryParameters['_mobileTheme'] == 'light'
              ? 'light'
              : 'dark';
          await browser.execute(
            "localStorage.setItem('crucix_theme', '$theme');",
          );
          await browser.load(target);
        case 'profile':
          onProfileChanged?.call();
        case 'ready':
          if (!policy.isDashboard(current)) return;
          _deadline?.cancel();
          isReady = true;
          notifyListeners();
        default:
          _navigation.handle(msg);
      }
    } catch (_) {
      fail();
    }
  }

  Future<void> _exchange() async {
    if (_exchanges >= 2) {
      fail();
      return;
    }
    isReady = false;
    notifyListeners();
    _deadline?.cancel();
    _deadline = Timer(const Duration(seconds: 35), fail);
    _isExchanging = true;
    final token = await getToken(_exchanges++ > 0);
    if (_isDisposed) return;
    final current = await browser.currentUri();
    if (current == null || !policy.isLogin(current)) {
      fail();
      return;
    }
    await browser.execute(DashboardScripts.bootstrap(token, _nonce));
  }

  void fail() {
    if (_isDisposed) return;
    _deadline?.cancel();
    error = 'Could not connect to the Dashboard. Check your connection and try again.';
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _deadline?.cancel();
    super.dispose();
  }
}
