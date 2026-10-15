import 'dart:convert';

/// Scripts contain only application-owned code and safely serialized values.
abstract final class DashboardScripts {
  static String bootstrap(String token, String nonce) =>
      '''
(async () => {
  try {
    const response = await fetch('/api/session', {
      method: 'POST', credentials: 'same-origin',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({idToken: ${jsonEncode(token)}})
    });
    MfbDashboard.postMessage(JSON.stringify({type:'session', ok:response.ok, nonce:${jsonEncode(nonce)}}));
  } catch (_) {
    MfbDashboard.postMessage(JSON.stringify({type:'session', ok:false, nonce:${jsonEncode(nonce)}}));
  }
})();
''';

  static String restore(double scroll) =>
      'window.__mfbRestoreScroll = ${scroll.isFinite ? scroll.clamp(0, 100000) : 0};';
}
