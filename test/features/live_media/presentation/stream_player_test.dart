import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';
import 'package:mfb_think_tank/features/live_media/application/playback_provider.dart';
import 'package:mfb_think_tank/features/live_media/presentation/stream_player.dart';

import '../../../helpers/fake_playback_engine.dart';

void main() {
  testWidgets(
    'hidden player is released, reentry creates exactly one replacement',
    (tester) async {
      final players = <FakePlaybackEngine>[];
      final request = PlaybackRequest(
        uri: Uri.parse('https://example.com/live.m3u8'),
        title: 'Live',
      );
      var active = true;
      late StateSetter update;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playbackFactoryProvider.overrideWithValue((request) {
              final p = FakePlaybackEngine(request);
              players.add(p);
              return p;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Scaffold(
                  body: StreamPlayer(request: request, isActive: active),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(players, hasLength(1));
      update(() => active = false);
      await tester.pumpAndSettle();
      expect(players.single.isDisposed, isTrue);
      update(() => active = true);
      await tester.pumpAndSettle();
      expect(players, hasLength(2));
      expect(players.last.isDisposed, isFalse);
    },
  );
  testWidgets('background releases ordinary playback and resumes fresh', (
    tester,
  ) async {
    final players = <FakePlaybackEngine>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackFactoryProvider.overrideWithValue((r) {
            final p = FakePlaybackEngine(r);
            players.add(p);
            return p;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: StreamPlayer(
              request: PlaybackRequest(
                uri: Uri.parse('https://example.com/live'),
                title: 'Live',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(players.single.isDisposed, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(players, hasLength(2));
  });
  testWidgets('explicit PiP stays alive in background and stops on tab leave', (
    tester,
  ) async {
    late FakePlaybackEngine player;
    var active = true;
    late StateSetter update;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackFactoryProvider.overrideWithValue(
            (r) => player = FakePlaybackEngine(r),
          ),
        ],
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return Scaffold(
                body: StreamPlayer(
                  isActive: active,
                  request: PlaybackRequest(
                    uri: Uri.parse('https://example.com/live'),
                    title: 'Live',
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    player.isInPip = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(player.isDisposed, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    update(() => active = false);
    await tester.pumpAndSettle();
    expect(player.isDisposed, isTrue);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
  testWidgets(
    'private stream failure refreshes credentials once without listener disposal races',
    (tester) async {
      final players = <FakePlaybackEngine>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playbackFactoryProvider.overrideWithValue((r) {
              final p = FakePlaybackEngine(r);
              players.add(p);
              return p;
            }),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StreamPlayer(
                request: PlaybackRequest(
                  uri: Uri.parse('https://example.com/file'),
                  title: 'Private',
                  headers: (force) async => {'Authorization': 'Bearer fixture'},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      players.first.fail();
      await tester.pumpAndSettle();
      expect(players, hasLength(2));
      expect(players.last.forcedRefresh, isTrue);
      players.last.fail();
      await tester.pumpAndSettle();
      expect(players, hasLength(2));
      expect(find.text('The stream failed.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
