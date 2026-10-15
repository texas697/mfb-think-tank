import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_failure.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_message.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_status.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_translation.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_gate.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_message_list.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_screen.dart';

import '../../../helpers/fake_telegram_repository.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    FakeTelegramRepository repo,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUidProvider.overrideWithValue('u1'),
          telegramRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('disconnected status never fetches dialogs and offers refresh', (
    tester,
  ) async {
    final repo = FakeTelegramRepository()
      ..status = const TelegramStatus(
        isConfigured: true,
        isAuthenticated: true,
        isConnected: false,
      );
    await pump(tester, repo, const TelegramScreen());
    expect(find.text('Telegram is unavailable'), findsOneWidget);
    expect(repo.dialogCalls, 0);
    repo.status = const TelegramStatus(
      isConfigured: true,
      isAuthenticated: true,
      isConnected: true,
    );
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(find.text('Iran updates'), findsOneWidget);
  });
  testWidgets('server errors are not presented as an empty directory', (
    tester,
  ) async {
    final repo = FakeTelegramRepository()
      ..error = const TelegramFailure('Offline');
    await pump(tester, repo, const TelegramScreen());
    expect(find.text('Could not load channels'), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('No channels published yet'), findsNothing);
  });
  testWidgets('translation displays first and original toggles independently', (
    tester,
  ) async {
    final repo = FakeTelegramRepository()
      ..messages = const [
        TelegramMessage(
          id: 1,
          text: 'متن اصلی',
          translation: TelegramTranslation(
            text: 'English translation',
            from: 'fa',
          ),
        ),
      ];
    await pump(
      tester,
      repo,
      const TelegramGate(child: TelegramMessageList(chatId: '-1001')),
    );
    expect(find.text('English translation'), findsOneWidget);
    expect(find.text('متن اصلی'), findsNothing);
    await tester.tap(find.byKey(const Key('telegram-original-1')));
    await tester.pumpAndSettle();
    expect(find.text('متن اصلی'), findsOneWidget);
    await tester.tap(find.byKey(const Key('telegram-original-1')));
    await tester.pumpAndSettle();
    expect(find.text('متن اصلی'), findsNothing);
  });
  testWidgets(
    'a late result from the previous channel cannot replace the selected channel',
    (tester) async {
      final first = Completer<List<TelegramMessage>>();
      final repo = FakeTelegramRepository()
        ..onMessages = (id) => id == 'first'
            ? first.future
            : Future.value(const [
                TelegramMessage(id: 2, text: 'Second channel'),
              ]);
      var id = 'first';
      late StateSetter update;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUidProvider.overrideWithValue('u1'),
            telegramRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return TelegramMessageList(chatId: id);
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      update(() => id = 'second');
      await tester.pumpAndSettle();
      expect(find.text('Second channel'), findsOneWidget);
      first.complete(const [TelegramMessage(id: 1, text: 'First channel')]);
      await tester.pumpAndSettle();
      expect(find.text('Second channel'), findsOneWidget);
      expect(find.text('First channel'), findsNothing);
    },
  );
}
