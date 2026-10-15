import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/core/playback/better_playback_engine.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';
import 'package:mfb_think_tank/features/auth/application/api_client_providers.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/live_media/application/playback_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../test/helpers/fake_digest_repository.dart';
import '../test/helpers/mocks.dart';

class _FixtureTokens implements IdTokenProvider {
  @override
  Future<String> getIdToken({bool forceRefresh = false}) async =>
      'mobile-fixture-token';
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const fixture = String.fromEnvironment(
    'PARITY_FIXTURE_URL',
    defaultValue: 'http://127.0.0.1:4175',
  );
  Future<void> until(WidgetTester tester, bool Function() condition) async {
    for (var i = 0; i < 200; i++) {
      if (condition()) return;
      await tester.pump(const Duration(milliseconds: 250));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }
    expect(
      condition(),
      isTrue,
      reason:
          'Timed out waiting for native UI: ${tester.widgetList<Text>(find.byType(Text)).map((text) => text.data).join(' | ')}',
    );
  }

  Future<void> webUntil(
    WidgetTester tester,
    WebViewController controller,
    String condition,
  ) async {
    for (var i = 0; i < 100; i++) {
      final value = await controller.runJavaScriptReturningResult(condition);
      if (value == true || value == 'true') return;
      await tester.pump(const Duration(milliseconds: 300));
    }
    final url = await controller.currentUrl();
    final body = await controller.runJavaScriptReturningResult(
      'document.body?.innerText.slice(0, 1200)',
    );
    fail(
      'Timed out waiting for web condition: $condition; url=$url; body=$body',
    );
  }

  testWidgets(
    'four surfaces use native navigation, private media and full web dashboard',
    (tester) async {
      final players = <BetterPlaybackEngine>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateChangesProvider.overrideWith(
              (_) => Stream.value(fakeAppUser()),
            ),
            currentUserProvider.overrideWith(
              (_) => Stream.value(fakeAppUser()),
            ),
            idTokenProvider.overrideWithValue(_FixtureTokens()),
            appConfigProvider.overrideWithValue(
              const AppConfig(crucixApiBaseUrl: fixture),
            ),
            digestRepositoryProvider.overrideWithValue(
              FakeDigestRepository(
                items: [
                  fakeCard(
                    'a',
                    title: 'Regional security and the global economy',
                  ),
                  fakeCard(
                    'b',
                    title: 'Technology policy and the next decade',
                    kind: 'thinktank',
                  ),
                ],
              ),
            ),
            playbackFactoryProvider.overrideWithValue((request) {
              final player = BetterPlaybackEngine(
                PlaybackRequest(
                  uri: request.isLive
                      ? Uri.parse('$fixture/fixture-media/index.m3u8')
                      : request.uri,
                  title: request.title,
                  isLive: request.isLive,
                  isPreview: request.isPreview,
                  isAutoPlay: request.isAutoPlay,
                  isAudio: request.isAudio,
                  volume: request.volume,
                  headers: request.headers,
                ),
              );
              players.add(player);
              return player;
            }),
          ],
          child: const App(),
        ),
      );
      await until(
        tester,
        () => find.byKey(const Key('nav-0')).evaluate().isNotEmpty,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(App)),
      );
      expect(
        container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        AppRoutes.dashboard,
      );

      await until(
        tester,
        () => find.byType(WebViewWidget).evaluate().isNotEmpty,
      );
      final web = WebViewController.fromPlatform(
        tester
            .widget<WebViewWidget>(find.byType(WebViewWidget))
            .platform
            .params
            .controller,
      );
      await web.setOnConsoleMessage((message) {
        debugPrint('Dashboard fixture: ${message.level}: ${message.message}');
      });
      await webUntil(
        tester,
        web,
        "!!document.querySelector('[data-layer=thermal]') && !!document.querySelector('#mapContainer canvas')",
      );
      expect(
        await web.runJavaScriptReturningResult(
          "getComputedStyle(document.querySelector('.crucix-app-left')).display === 'none'",
        ),
        true,
      );
      expect(
        await web.runJavaScriptReturningResult(
          "getComputedStyle(document.querySelector('.crucix-map-controls')).display === 'none'",
        ),
        true,
      );
      await web.runJavaScript(
        "document.querySelector('[data-region=europe]').click();",
      );
      await webUntil(tester, web, "location.search.includes('region=europe')");
      await web.runJavaScript(
        "document.querySelector('[data-layer=thermal]').click();",
      );
      await webUntil(
        tester,
        web,
        "document.querySelector('[data-layer=thermal]').classList.contains('crucix-map-legend-chip--off')",
      );
      await webUntil(
        tester,
        web,
        "document.querySelector('#mapContainer canvas')?.getBoundingClientRect().height > 100",
      );
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      debugPrint('PARITY_CAPTURE_dashboard');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );

      await tester.tap(find.byKey(const Key('nav-2')));
      await tester.pump();
      await until(tester, () => players.isNotEmpty && players.last.isReady);
      expect(players.last.error, isNull);
      await tester.tap(find.byKey(const Key('channel-rt')));
      await tester.pump();
      await until(
        tester,
        () => players.last.request.title == 'RT' && players.last.isReady,
      );
      final mainPlayer = players.last;
      mainPlayer.toggleFullscreen();
      await tester.pump(const Duration(milliseconds: 500));
      expect(mainPlayer.controller.isFullScreen, isTrue);
      mainPlayer.toggleFullscreen();
      await tester.pump(const Duration(milliseconds: 500));
      expect(mainPlayer.controller.isFullScreen, isFalse);
      expect(await mainPlayer.controller.isPictureInPictureSupported(), isTrue);
      await until(
        tester,
        () => find
            .byKey(const Key('player-pip'))
            .hitTestable()
            .evaluate()
            .isNotEmpty,
      );
      await tester.tap(find.byKey(const Key('player-pip')));
      await tester.runAsync(() async {
        for (var i = 0; i < 20 && !mainPlayer.isInPip; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
        expect(mainPlayer.isInPip, isTrue);
        debugPrint('PARITY_PIP_STARTED');
        await Future<void>.delayed(const Duration(seconds: 3));
      });
      await until(tester, () => !mainPlayer.isInPip);
      if (mainPlayer.controller.isFullScreen) mainPlayer.toggleFullscreen();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('media-grid')));
      await tester.pump();
      await until(
        tester,
        () =>
            players.where((p) => p.request.isPreview && p.isReady).length >= 4,
      );
      await tester.ensureVisible(find.byKey(const Key('grid-presstv')));
      await tester.pump(const Duration(milliseconds: 500));
      debugPrint('PARITY_CAPTURE_media');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );

      await tester.tap(find.byKey(const Key('nav-3')));
      await tester.pump();
      await until(
        tester,
        () =>
            find.byKey(const Key('telegram-chat--1001')).evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const Key('telegram-chat--1001')));
      await tester.pump();
      await until(
        tester,
        () => find.text('A translated field update').evaluate().isNotEmpty,
      );
      await tester.tap(find.byKey(const Key('telegram-original-3')));
      await tester.pump();
      expect(find.text('گزارش میدانی'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('telegram-play-1')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey('telegram-messages--1001')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.ensureVisible(find.byKey(const Key('telegram-play-1')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('telegram-play-1')));
      await tester.pump();
      await until(
        tester,
        () =>
            players.last.request.title == 'Telegram video' &&
            players.last.isReady,
      );
      expect(players.last.error, isNull);
      debugPrint('PARITY_CAPTURE_telegram');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      final stats = jsonDecode(
        (await http.get(Uri.parse('$fixture/__fixture/stats'))).body,
      ) as Map<String, dynamic>;
      expect(stats['sessions'], greaterThanOrEqualTo(1));
      expect(stats['privateImages'], greaterThanOrEqualTo(1));
      expect(stats['privateFiles'], greaterThanOrEqualTo(1));
      expect(
        stats['events'],
        0,
        reason: 'Dashboard must close SSE when hidden',
      );

      container.read(routerProvider).go('/dashboard');
      await tester.pump();
      await until(
        tester,
        () => find.byType(WebViewWidget).evaluate().isNotEmpty,
      );
      final restored = WebViewController.fromPlatform(
        tester
            .widget<WebViewWidget>(find.byType(WebViewWidget))
            .platform
            .params
            .controller,
      );
      await webUntil(
        tester,
        restored,
        "location.search.includes('region=europe') && !!document.querySelector('#mapContainer')",
      );
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
      await binding.takeScreenshot('dashboard-android');
      expect(tester.takeException(), isNull);
    },
  );
}
