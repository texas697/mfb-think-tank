import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';

import '../helpers/fake_digest_repository.dart';
import '../helpers/mocks.dart';

void main() {
  group('authRedirect', () {
    const user = AppUser(uid: 'u1');
    const loading = AsyncLoading<AppUser?>();
    const signedOut = AsyncData<AppUser?>(null);
    const signedIn = AsyncData<AppUser?>(user);

    String? redirect(
      AsyncValue<AppUser?> state,
      String location, {
      bool rememberLocation = true,
    }) => authRedirect(
      authState: state,
      uri: Uri.parse(location),
      rememberLocation: rememberLocation,
    );

    test('shows the splash screen until auth state is known', () {
      expect(redirect(loading, AppRoutes.dashboard), AppRoutes.splash);
      expect(redirect(loading, AppRoutes.signIn), AppRoutes.splash);
      expect(redirect(loading, AppRoutes.splash), isNull);
    });

    test('keeps a cold-start deep link while auth state is loading', () {
      expect(
        redirect(loading, AppRoutes.profile),
        '${AppRoutes.splash}?from=%2Fprofile',
      );
      expect(redirect(loading, '${AppRoutes.splash}?from=%2Fprofile'), isNull);
      // Signed out: forwarded to sign-in.
      expect(
        redirect(signedOut, '${AppRoutes.splash}?from=%2Fprofile'),
        '${AppRoutes.signIn}?from=%2Fprofile',
      );
      expect(
        redirect(
          signedOut,
          '${AppRoutes.splash}?from=%2Fprofile',
          rememberLocation: false,
        ),
        AppRoutes.signIn,
      );
      // Signed in: restored directly.
      expect(
        redirect(signedIn, '${AppRoutes.splash}?from=%2Fprofile'),
        AppRoutes.profile,
      );
    });

    test('sends signed-out users to sign-in', () {
      expect(redirect(signedOut, AppRoutes.splash), AppRoutes.signIn);
      expect(redirect(signedOut, AppRoutes.dashboard), AppRoutes.signIn);
    });

    test('lets signed-out users use the auth screens', () {
      for (final route in AppRoutes.signedOutOnly) {
        expect(redirect(signedOut, route), isNull, reason: route);
      }
    });

    test('remembers deep links for after sign-in', () {
      expect(
        redirect(signedOut, AppRoutes.profile),
        '${AppRoutes.signIn}?from=%2Fprofile',
      );
      expect(
        redirect(signedOut, AppRoutes.profile, rememberLocation: false),
        AppRoutes.signIn,
      );
    });

    test('sends signed-in users away from auth screens', () {
      expect(redirect(signedIn, AppRoutes.splash), AppRoutes.dashboard);
      expect(redirect(signedIn, AppRoutes.signIn), AppRoutes.dashboard);
      expect(redirect(signedIn, AppRoutes.signUp), AppRoutes.dashboard);
      expect(redirect(signedIn, AppRoutes.forgotPassword), AppRoutes.dashboard);
    });

    test('restores the remembered location after sign-in', () {
      expect(
        redirect(signedIn, '${AppRoutes.signIn}?from=%2Fprofile'),
        AppRoutes.profile,
      );
    });

    test('preserves destination queries while Dashboard is the default', () {
      for (final destination in [
        '/?filter=news&q=policy',
        '/dashboard?region=europe',
      ]) {
        final loadingLocation = redirect(loading, destination)!;
        expect(Uri.parse(loadingLocation).queryParameters['from'], destination);
        final signInLocation = redirect(signedOut, loadingLocation)!;
        expect(redirect(signedIn, signInLocation), destination);
      }
      expect(redirect(signedIn, AppRoutes.home), isNull);
      expect(redirect(signedIn, AppRoutes.dashboard), isNull);
    });

    test('ignores unsafe "from" values', () {
      expect(
        redirect(signedIn, '${AppRoutes.signIn}?from=https://evil.example'),
        AppRoutes.dashboard,
      );
      expect(
        redirect(signedIn, '${AppRoutes.signIn}?from=//evil.example'),
        AppRoutes.dashboard,
      );
    });

    test('leaves signed-in users on protected routes', () {
      expect(redirect(signedIn, AppRoutes.home), isNull);
      expect(redirect(signedIn, AppRoutes.profile), isNull);
    });

    test('treats an auth error as signed out', () {
      final error = AsyncError<AppUser?>(Exception('x'), StackTrace.empty);
      expect(redirect(error, AppRoutes.dashboard), AppRoutes.signIn);
    });
  });

  group('router + auth state', () {
    late MockFirebaseAuth auth;

    AuthRepository repositoryWith(FirebaseAuth auth) => FirebaseAuthRepository(
      auth: auth,
      google: MockGoogleSignInGateway(),
      apple: MockAppleSignInGateway(),
      deletion: MockAccountDeletionGateway(),
    );

    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repositoryWith(auth)),
            digestRepositoryProvider.overrideWithValue(FakeDigestRepository()),
          ],
          child: const App(),
        ),
      );
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(tester.element(find.byType(App)));
    }

    String location(ProviderContainer container) => container
        .read(routerProvider)
        .routerDelegate
        .currentConfiguration
        .uri
        .toString();

    testWidgets(
      'signed-out users land on sign-in, then Dashboard after sign-in',
      (tester) async {
        auth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'u1', email: 'ann@example.com'),
        );
        final container = await pumpApp(tester);
        expect(location(container), AppRoutes.signIn);
        expect(find.text('Sign in to continue'), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('sign-in-email')),
          'ann@example.com',
        );
        await tester.enterText(
          find.byKey(const Key('sign-in-password')),
          'password1',
        );
        await tester.tap(find.byKey(const Key('sign-in-submit')));
        await tester.pumpAndSettle();

        expect(location(container), AppRoutes.dashboard);
        expect(find.byKey(const Key('open-account')), findsOneWidget);
      },
    );

    testWidgets('signing out from profile returns to sign-in', (tester) async {
      auth = MockFirebaseAuth(
        signedIn: true,
        mockUser: MockUser(uid: 'u1', email: 'ann@example.com'),
      );
      final container = await pumpApp(tester);
      expect(location(container), AppRoutes.dashboard);

      container.read(routerProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(find.text('ann@example.com'), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      // No "?from=/profile": an explicit sign-out starts fresh.
      expect(location(container), AppRoutes.signIn);
    });

    testWidgets('a signed-out deep link is restored after sign-in', (
      tester,
    ) async {
      auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'u1', email: 'a@b.co'),
      );
      final container = await pumpApp(tester);

      container.read(routerProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();
      expect(location(container), '${AppRoutes.signIn}?from=%2Fprofile');

      await auth.signInWithEmailAndPassword(email: 'a@b.co', password: 'x');
      await tester.pumpAndSettle();
      expect(location(container), AppRoutes.profile);
      expect(GoRouter.of(tester.element(find.text('Profile'))), isNotNull);
    });
  });
}
