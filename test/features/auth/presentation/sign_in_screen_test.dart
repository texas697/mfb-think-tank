import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';
import 'package:mfb_think_tank/features/auth/presentation/sign_in_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
    when(
      () => repository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
  });

  Future<void> pumpSignIn(
    WidgetTester tester, {
    SocialSignInOptions options = const SocialSignInOptions(
      showGoogle: true,
      googleConfigured: true,
      showApple: false,
    ),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SignInScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, state) =>
              Text('forgot:${state.uri.queryParameters['email']}'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          socialSignInOptionsProvider.overrideWithValue(options),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder field(String key) => find.byKey(Key(key));

  testWidgets('shows validation errors and does not submit empty form', (
    tester,
  ) async {
    await pumpSignIn(tester);

    await tester.tap(field('sign-in-submit'));
    await tester.pump();

    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    verifyNever(
      () => repository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('rejects an invalid email', (tester) async {
    await pumpSignIn(tester);

    await tester.enterText(field('sign-in-email'), 'nope');
    await tester.enterText(field('sign-in-password'), 'secret');
    await tester.tap(field('sign-in-submit'));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('submits valid credentials', (tester) async {
    await pumpSignIn(tester);

    await tester.enterText(field('sign-in-email'), 'ann@example.com');
    await tester.enterText(field('sign-in-password'), 'secret');
    await tester.tap(field('sign-in-submit'));
    await tester.pumpAndSettle();

    verify(
      () => repository.signInWithEmail(
        email: 'ann@example.com',
        password: 'secret',
      ),
    ).called(1);
  });

  testWidgets('shows auth failures in a snackbar', (tester) async {
    when(
      () => repository.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const AuthFailure('wrong-password', 'Incorrect email or password.'),
    );
    await pumpSignIn(tester);

    await tester.enterText(field('sign-in-email'), 'ann@example.com');
    await tester.enterText(field('sign-in-password'), 'bad');
    await tester.tap(field('sign-in-submit'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('stays silent when a social sign-in is cancelled', (
    tester,
  ) async {
    when(() => repository.signInWithGoogle())
        .thenThrow(const AuthFailure.cancelled());
    await pumpSignIn(tester);

    await tester.tap(field('google-sign-in'));
    await tester.pumpAndSettle();

    verify(() => repository.signInWithGoogle()).called(1);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('disables Google with a hint when not configured', (
    tester,
  ) async {
    await pumpSignIn(
      tester,
      options: const SocialSignInOptions(
        showGoogle: true,
        googleConfigured: false,
        showApple: false,
      ),
    );

    final button = tester.widget<ButtonStyleButton>(field('google-sign-in'));
    expect(button.onPressed, isNull);
    expect(find.textContaining('not configured'), findsOneWidget);
  });

  testWidgets('shows Apple only when offered (iOS)', (tester) async {
    await pumpSignIn(tester);
    expect(field('apple-sign-in'), findsNothing);

    await pumpSignIn(
      tester,
      options: const SocialSignInOptions(
        showGoogle: true,
        googleConfigured: true,
        showApple: true,
      ),
    );
    expect(field('apple-sign-in'), findsOneWidget);
  });

  testWidgets('forgot password carries the typed email', (tester) async {
    await pumpSignIn(tester);

    await tester.enterText(field('sign-in-email'), 'ann@example.com');
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('forgot:ann@example.com'), findsOneWidget);
  });
}
