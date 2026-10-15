import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/dashboard/application/dashboard_session.dart';
import 'package:mfb_think_tank/features/dashboard/data/dashboard_browser_port.dart';
import 'package:mfb_think_tank/features/dashboard/data/dashboard_policy.dart';

class _Browser implements DashboardBrowserPort {
  Uri? current;
  final loads = <Uri>[];
  final scripts = <String>[];
  @override
  Future<void> load(Uri uri) async {
    current = uri;
    loads.add(uri);
  }

  @override
  Future<Uri?> currentUri() async => current;
  @override
  Future<void> execute(String script) async {
    scripts.add(script);
  }
}

void main() {
  final base = Uri.parse('https://api.example');
  late _Browser browser;
  late List<bool> tokens;
  late List<String> navigations;
  late List<Uri> external;
  DashboardSession session({Future<String> Function(bool)? token}) {
    browser = _Browser();
    tokens = [];
    navigations = [];
    external = [];
    final value = DashboardSession(
      browser: browser,
      policy: DashboardPolicy(base),
      getToken:
          token ??
          (force) async {
            tokens.add(force);
            return 'fixture-token';
          },
      embedScript: 'const nonce=__MFB_NONCE__;',
      bridgeNonce: 'test-nonce',
      onLocation: (_, _) {},
      onNavigate: navigations.add,
      onExternal: external.add,
      resume: base.resolve('/?region=europe'),
      scroll: 500,
    );
    addTearDown(value.dispose);
    return value;
  }

  String message(
    String type, {
    bool? ok,
    String? url,
    String nonce = 'test-nonce',
  }) => jsonEncode({'type': type, 'nonce': nonce, 'ok': ok, 'url': url});

  test(
    'trusted login bootstrap uses a body token, then restores dashboard',
    () async {
      final s = session();
      await s.start();
      expect(browser.loads.single, base.resolve('/login'));
      await s.pageFinished(browser.current.toString());
      expect(tokens, [false]);
      expect(
        browser.scripts.single,
        contains('JSON.stringify({idToken: "fixture-token"})'),
      );
      expect(
        browser.loads.every((u) => !u.toString().contains('fixture-token')),
        isTrue,
      );
      await s.message(message('session', ok: true));
      expect(browser.current, base.resolve('/?region=europe'));
      await s.pageFinished(browser.current.toString());
      expect(browser.scripts.join(), contains('const nonce="test-nonce";'));
      expect(browser.scripts.join(), contains('500'));
      await s.message(message('ready'));
      expect(s.isReady, isTrue);
      expect(s.error, isNull);
    },
  );
  test(
    'rejected exchange forces one fresh token and stops after second rejection',
    () async {
      final s = session();
      await s.start();
      await s.pageFinished(browser.current.toString());
      await s.message(message('session', ok: false));
      expect(tokens, [false, true]);
      await s.message(message('session', ok: false));
      expect(tokens, [false, true]);
      expect(s.error, isNotNull);
    },
  );
  test(
    'redirecting away while token resolves never injects a token off-origin',
    () async {
      final gate = Completer<String>();
      final s = session(token: (_) => gate.future);
      await s.start();
      final pending = s.pageFinished(browser.current.toString());
      browser.current = Uri.parse('https://evil.example/login');
      gate.complete('private-token');
      await pending;
      expect(browser.scripts, isEmpty);
      expect(s.error, isNotNull);
    },
  );
  test(
    'messages from a foreign page or without the bridge nonce are ignored',
    () async {
      final s = session();
      await s.start();
      await s.message(
        message(
          'navigate',
          url: 'https://api.example/telegram/123',
          nonce: 'forged',
        ),
      );
      browser.current = Uri.parse('https://evil.example/');
      await s.message(
        message('navigate', url: 'https://api.example/telegram/123'),
      );
      expect(navigations, isEmpty);
    },
  );
  test(
    'native surface routes preserve grid and external schemes are filtered',
    () async {
      final s = session();
      await s.start();
      browser.current = base.resolve('/');
      await s.message(
        message('navigate', url: 'https://api.example/media/rt?grid=1'),
      );
      await s.message(message('navigate', url: 'https://api.example/digest/a'));
      await s.message(message('navigate', url: 'javascript:alert(1)'));
      await s.message(message('navigate', url: 'https://news.example/story'));
      expect(navigations, ['/media/rt?grid=1', '/article/a']);
      expect(external, [Uri.parse('https://news.example/story')]);
    },
  );
  test('exact origin boundary handles executable and lookalike URLs without throwing', () {
    final policy = DashboardPolicy(base);
    for (final url in [
      'javascript:alert(1)',
      'data:text/html,test',
      'about:blank',
      'https://api.example.evil.test/',
      'http://api.example/',
      'https://user@api.example/',
    ]) {
      expect(policy.isTrusted(Uri.parse(url)), isFalse, reason: url);
    }
    expect(
      () => DashboardPolicy(Uri.parse('http://remote.example')),
      throwsArgumentError,
    );
  });
}
