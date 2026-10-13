import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/digest_settings/data/ai_settings.dart';
import 'package:mfb_think_tank/features/digest_settings/presentation/account_sheet.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';

import '../../../helpers/fake_settings_repository.dart';

void main() {
  late FakeSettingsRepository repo;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          firebaseAuthProvider.overrideWithValue(
            MockFirebaseAuth(
              signedIn: true,
              mockUser: MockUser(uid: 'u1', email: 'ann@example.com'),
            ),
          ),
          digestSettingsRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(home: Scaffold(body: AccountSheet())),
      ),
    );
    await tester.pumpAndSettle();
  }

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
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gemini').last);
    await tester.pumpAndSettle();
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

  testWidgets('disables the form when the server cannot store keys', (
    tester,
  ) async {
    repo = FakeSettingsRepository(byokEnabled: false);
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
