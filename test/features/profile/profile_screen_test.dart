import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/profile/presentation/profile_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late MockFirebaseUser user;

  setUp(() {
    repository = MockAuthRepository();
    user = MockFirebaseUser();
    when(() => user.email).thenReturn('ann@example.com');
    when(() => user.displayName).thenReturn('Ann');
    when(() => user.emailVerified).thenReturn(true);
    when(() => repository.deleteAccount(password: any(named: 'password')))
        .thenAnswer((_) async {});
  });

  Future<void> pumpProfile(WidgetTester tester, List<String> providers) async {
    when(() => user.providerData)
        .thenReturn([for (final id in providers) FakeUserInfo(id)]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          currentUserProvider.overrideWith((ref) => Stream<User?>.value(user)),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openDeleteDialog(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('delete-account')));
    await tester.tap(find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();
  }

  testWidgets('password users must confirm with their password', (
    tester,
  ) async {
    await pumpProfile(tester, [AuthProviderIds.password]);
    await openDeleteDialog(tester);

    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pump();
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('delete-account-password')),
      'secret',
    );
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();

    verify(() => repository.deleteAccount(password: 'secret')).called(1);
  });

  testWidgets('social users confirm without a password', (tester) async {
    await pumpProfile(tester, [AuthProviderIds.google]);
    await openDeleteDialog(tester);

    expect(find.byKey(const Key('delete-account-password')), findsNothing);
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();

    verify(() => repository.deleteAccount()).called(1);
  });

  testWidgets('cancelling the dialog deletes nothing', (tester) async {
    await pumpProfile(tester, [AuthProviderIds.google]);
    await openDeleteDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(
      () => repository.deleteAccount(password: any(named: 'password')),
    );
  });
}
