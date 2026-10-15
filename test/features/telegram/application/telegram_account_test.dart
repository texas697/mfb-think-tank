import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_message.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_status.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_chat_screen.dart';

import '../../../helpers/fake_telegram_repository.dart';

void main() {
  test('late data for the same channel in the previous account cannot replace new account data', () async {
    final old = Completer<List<TelegramMessage>>();
    var calls = 0;
    final repo = FakeTelegramRepository()
      ..onMessages = (_) => calls++ == 0
          ? old.future
          : Future.value(const [TelegramMessage(id: 2, text: 'New account')]);
    final container = ProviderContainer(
      overrides: [telegramRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    final a = container.listen(
      telegramMessagesProvider(('a', 'same-channel')),
      (_, _) {},
    );
    addTearDown(a.close);
    await container.pump();
    final b = container.listen(
      telegramMessagesProvider(('b', 'same-channel')),
      (_, _) {},
    );
    addTearDown(b.close);
    expect(
      container.read(telegramMessagesProvider(('b', 'same-channel'))).value,
      isNull,
    );
    expect(
      (await container.read(
        telegramMessagesProvider(('b', 'same-channel')).future,
      )).single.text,
      'New account',
    );
    old.complete(const [
      TelegramMessage(id: 1, text: 'Private previous account'),
    ]);
    await container.pump();
    expect(
      container
          .read(telegramMessagesProvider(('b', 'same-channel')))
          .requireValue
          .single
          .text,
      'New account',
    );
  });

  testWidgets(
    'switching accounts hides the previous channel title while new status is loading',
    (tester) async {
      final repo = FakeTelegramRepository();
      final pending = Completer<TelegramStatus>();
      var uid = 'a';
      late StateSetter update;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return ProviderScope(
              overrides: [
                currentUidProvider.overrideWithValue(uid),
                telegramRepositoryProvider.overrideWithValue(repo),
              ],
              child: const MaterialApp(
                home: Scaffold(body: TelegramChatScreen(chatId: '-1001')),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Iran updates'), findsOneWidget);
      repo.onStatus = () => pending.future;
      update(() => uid = 'b');
      await tester.pump();
      await tester.pump();
      expect(find.text('Iran updates'), findsNothing);
      expect(find.text('Telegram channel'), findsOneWidget);
      pending.complete(
        const TelegramStatus(
          isConfigured: false,
          isAuthenticated: false,
          isConnected: false,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Iran updates'), findsNothing);
      expect(find.text('Telegram is unavailable'), findsOneWidget);
    },
  );
}
