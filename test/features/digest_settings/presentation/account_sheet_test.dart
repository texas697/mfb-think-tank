import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/application/digest_settings_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/data/digest_settings_failure.dart';
import 'package:mfb_think_tank/features/digest_settings/presentation/account_sheet.dart';

import '../../../helpers/fake_settings_repository.dart';
import '../../../helpers/mocks.dart';

void main() {
  late FakeSettingsRepository repo;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(fakeAppUser()),
          ),
          currentUserProvider.overrideWith(
            (ref) => Stream.value(fakeAppUser()),
          ),
          digestSettingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: Scaffold(body: AccountSheet())),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, String key) =>
      tester.widget<TextField>(find.byKey(Key(key))).enabled ?? true;

  testWidgets('shows the account and requires a key for the first save', (
    tester,
  ) async {
    repo = FakeSettingsRepository();
    await pump(tester);
    expect(find.text('ann@example.com'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai-save')));
    await tester.pump();
    expect(find.text('Enter an API key.'), findsOneWidget);
    expect(repo.saved, isEmpty);

    await tester.enterText(find.byKey(const Key('ai-key')), 'sk-secret');
    await tester.tap(find.byKey(const Key('ai-save')));
    await tester.pumpAndSettle();
    expect(repo.saved.single.provider, 'anthropic');
    expect(repo.saved.single.apiKey, 'sk-secret');
    expect(find.text('Key saved.'), findsOneWidget);
    // The raw key is cleared after saving.
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('ai-key')))
          .controller!
          .text,
      isEmpty,
    );
  });

  testWidgets('a same-provider update keeps the stored key', (tester) async {
    repo = FakeSettingsRepository(
      llm: const AiSettings(
        provider: 'openai',
        model: 'gpt',
        hasKey: true,
        keyHint: '…9999',
      ),
    );
    await pump(tester);
    await tester.enterText(find.byKey(const Key('ai-model')), 'gpt-next');
    await tester.tap(find.byKey(const Key('ai-save')));
    await tester.pumpAndSettle();
    expect(repo.saved.single.model, 'gpt-next');
    expect(repo.saved.single.apiKey, isNull);
    expect(repo.saved.single.toJson().containsKey('apiKey'), isFalse);
  });

  testWidgets('switching provider needs a replacement key', (tester) async {
    repo = FakeSettingsRepository(
      llm: const AiSettings(provider: 'openai', hasKey: true),
    );
    await pump(tester);
    await tester.tap(find.byKey(const Key('ai-provider')));
    await tester.pumpAndSettle();
    // Tap the item's label: the item itself is a loose alignment box.
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('ai-provider-gemini')),
        matching: find.byType(Text),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Gemini'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai-save')));
    await tester.pump();
    expect(find.text('Enter an API key.'), findsOneWidget);
    expect(repo.saved, isEmpty);
  });

  testWidgets('tests and removes the saved key', (tester) async {
    repo = FakeSettingsRepository(
      llm: const AiSettings(provider: 'anthropic', hasKey: true),
    );
    await pump(tester);
    await tester.tap(find.byKey(const Key('ai-test')));
    await tester.pumpAndSettle();
    expect(repo.tests, 1);
    expect(find.text('Key verified.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('ai-remove')));
    await tester.pumpAndSettle();
    expect(repo.removed, 1);
    expect(find.byKey(const Key('ai-remove')), findsNothing);
  });

  testWidgets('a saved keyless provider still offers Test and Remove', (
    tester,
  ) async {
    repo = FakeSettingsRepository(
      llm: const AiSettings(
        provider: 'openai-compatible',
        baseUrl: 'http://llm.local/v1',
      ),
    );
    await pump(tester);
    expect(find.byKey(const Key('ai-test')), findsOneWidget);
    expect(find.byKey(const Key('ai-remove')), findsOneWidget);
    expect(find.byKey(const Key('ai-key')), findsNothing);
    await tester.tap(find.byKey(const Key('ai-test')));
    await tester.pumpAndSettle();
    expect(repo.tests, 1);
  });

  testWidgets('shows progress on the active button and locks the fields', (
    tester,
  ) async {
    repo = FakeSettingsRepository(
      llm: const AiSettings(provider: 'anthropic', hasKey: true),
    );
    await pump(tester);
    expect(find.text('Update'), findsOneWidget);
    expect(isEnabled(tester, 'ai-model'), isTrue);

    repo.gate = Completer<void>();
    await tester.tap(find.byKey(const Key('ai-save')));
    await tester.pump();
    expect(find.text('Saving…'), findsOneWidget);
    expect(find.text('Testing…'), findsNothing);
    expect(isEnabled(tester, 'ai-model'), isFalse);
    expect(isEnabled(tester, 'ai-key'), isFalse);
    expect(
      tester.widget<OutlinedButton>(find.byKey(const Key('ai-test'))).onPressed,
      isNull,
    );

    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Saving…'), findsNothing);
    expect(find.text('Update'), findsOneWidget);
    expect(isEnabled(tester, 'ai-model'), isTrue);

    repo.gate = Completer<void>();
    await tester.tap(find.byKey(const Key('ai-test')));
    await tester.pump();
    expect(find.text('Testing…'), findsOneWidget);
    expect(find.text('Saving…'), findsNothing);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Key verified.'), findsOneWidget);
  });

  testWidgets('shows the failure message when settings cannot load', (
    tester,
  ) async {
    repo = FakeSettingsRepository(fetchError: const SettingsUnavailable());
    await pump(tester);
    expect(find.byKey(const Key('account-error')), findsOneWidget);
    expect(find.text('Could not load settings.'), findsOneWidget);
    expect(find.text(const SettingsUnavailable().message), findsOneWidget);
    expect(find.byKey(const Key('ai-save')), findsNothing);

    repo.fetchError = null;
    await tester.tap(find.byKey(const Key('feed-message-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('account-error')), findsNothing);
    expect(find.byKey(const Key('ai-save')), findsOneWidget);
  });

  testWidgets('disables the form when the server cannot store keys', (
    tester,
  ) async {
    repo = FakeSettingsRepository(isByokEnabled: false);
    await pump(tester);
    expect(
      find.text('Key storage is not enabled on this server.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byKey(const Key('ai-save'))).onPressed,
      isNull,
    );
  });
}
