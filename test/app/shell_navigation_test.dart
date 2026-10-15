import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/live_media/application/playback_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';

import '../helpers/fake_digest_repository.dart';
import '../helpers/fake_playback_engine.dart';
import '../helpers/fake_telegram_repository.dart';
import '../helpers/mocks.dart';

void main() {
  final players = <FakePlaybackEngine>[];
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    double width = 390,
    double scale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    players.clear();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (_) => Stream.value(fakeAppUser()),
          ),
          currentUserProvider.overrideWith((_) => Stream.value(fakeAppUser())),
          digestRepositoryProvider.overrideWithValue(
            FakeDigestRepository(items: [fakeCard('a')]),
          ),
          telegramRepositoryProvider.overrideWithValue(
            FakeTelegramRepository(),
          ),
          playbackFactoryProvider.overrideWithValue((PlaybackRequest request) {
            final engine = FakePlaybackEngine(request);
            players.add(engine);
            return engine;
          }),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(App)));
  }

  testWidgets(
    'all four destinations preserve the Digest filter and stop hidden media',
    (tester) async {
      final c = await pump(tester);
      c.read(routerProvider).go('/?filter=news&q=policy');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('nav-2')));
      await tester.pumpAndSettle();
      expect(find.text('Six perspectives. One live picture.'), findsOneWidget);
      expect(players.where((p) => !p.isDisposed), hasLength(1));
      await tester.tap(find.byKey(const Key('nav-3')));
      await tester.pumpAndSettle();
      expect(find.text('Iran updates'), findsOneWidget);
      expect(players.every((p) => p.isDisposed), isTrue);
      await tester.tap(find.byKey(const Key('nav-0')));
      await tester.pumpAndSettle();
      expect(find.text('Your global intelligence picture.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      expect(
        c
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .toString(),
        '/?filter=news&q=policy',
      );
      expect(find.byKey(const Key('open-account')), findsOneWidget);
    },
  );

  testWidgets('media channel and monitor state survive tab switches', (
    tester,
  ) async {
    final c = await pump(tester);
    c.read(routerProvider).go('/media/rt?grid=1');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('channel-rt')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nav-1')));
    await tester.pumpAndSettle();
    expect(players.every((p) => p.isDisposed), isTrue);
    await tester.tap(find.byKey(const Key('nav-2')));
    await tester.pumpAndSettle();
    expect(
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.toString(),
      '/media/rt?grid=1',
    );
    expect(find.text('RT'), findsWidgets);
  });

  testWidgets('Telegram search survives reading a channel and returning', (
    tester,
  ) async {
    final c = await pump(tester);
    c.read(routerProvider).go(AppRoutes.telegram);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('telegram-search')), 'Iran');
    await tester.pumpAndSettle();
    expect(find.text('Europe news'), findsNothing);
    await tester.tap(find.byKey(const Key('telegram-chat--1001')));
    await tester.pumpAndSettle();
    expect(find.text('No messages yet'), findsOneWidget);
    await tester.tap(find.byKey(const Key('telegram-back')));
    await tester.pumpAndSettle();
    expect(find.text('Europe news'), findsNothing);
    expect(find.text('Iran updates'), findsOneWidget);
  });

  for (final width in [320.0, 768.0, 1024.0]) {
    testWidgets('navigation fits width $width with enlarged text', (
      tester,
    ) async {
      final c = await pump(tester, width: width, scale: 1.6);
      c.read(routerProvider).go('/media/rt');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      c.read(routerProvider).go(AppRoutes.telegram);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
