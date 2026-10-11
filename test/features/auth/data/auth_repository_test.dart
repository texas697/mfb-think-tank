import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/auth/data/apple_sign_in_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/auth/data/nonce.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

const _rawNonce = 'fixed-raw-nonce';
const _appleCredential = AppleIdCredential(
  identityToken: 'apple-id-token',
  authorizationCode: 'apple-auth-code',
  givenName: 'Ann',
  familyName: 'Lee',
);

TypeMatcher<AuthFailure> _failureWithCode(String code) =>
    isA<AuthFailure>().having((f) => f.code, 'code', code);

void main() {
  setUpAll(registerAuthFallbackValues);

  late MockGoogleSignInGateway google;
  late MockAppleSignInGateway apple;

  setUp(() {
    google = MockGoogleSignInGateway();
    apple = MockAppleSignInGateway();
    when(() => google.signOut()).thenAnswer((_) async {});
    when(() => google.disconnect()).thenAnswer((_) async {});
  });

  FirebaseAuthRepository repositoryWith(FirebaseAuth auth) =>
      FirebaseAuthRepository(
        auth: auth,
        google: google,
        apple: apple,
        nonceGenerator: () => _rawNonce,
      );

  group('with firebase_auth_mocks', () {
    late MockFirebaseAuth auth;
    late FirebaseAuthRepository repository;

    setUp(() {
      auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-1', email: 'ann@example.com'),
      );
      repository = repositoryWith(auth);
    });

    test('authStateChanges emits null then the signed-in user', () async {
      final events = repository.authStateChanges().take(2).toList();
      await repository.signInWithEmail(
        email: ' ann@example.com ',
        password: 'pw',
      );
      final users = await events;
      expect(users.first, isNull);
      expect(users.last?.uid, 'uid-1');
    });

    test('signInWithEmail signs in', () async {
      await repository.signInWithEmail(email: 'ann@example.com', password: 'p');
      expect(repository.currentUser?.uid, 'uid-1');
    });

    test('signInWithEmail maps Firebase errors to AuthFailure', () async {
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'wrong-password'));

      await expectLater(
        repository.signInWithEmail(email: 'ann@example.com', password: 'bad'),
        throwsA(
          _failureWithCode(
            'wrong-password',
          ).having((f) => f.message, 'message', 'Incorrect email or password.'),
        ),
      );
      expect(repository.currentUser, isNull);
    });

    test('signUpWithEmail creates the user and sets the name', () async {
      await repository.signUpWithEmail(
        email: 'new@example.com',
        password: 'abcd1234',
        displayName: '  Ann Lee ',
      );
      expect(repository.currentUser?.email, 'new@example.com');
      expect(repository.currentUser?.displayName, 'Ann Lee');
    });

    test('signUpWithEmail surfaces email-already-in-use', () async {
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));

      await expectLater(
        repository.signUpWithEmail(email: 'a@b.co', password: 'abcd1234'),
        throwsA(_failureWithCode('email-already-in-use')),
      );
    });

    test('sendPasswordResetEmail maps errors', () async {
      await repository.sendPasswordResetEmail('ann@example.com');

      whenCalling(Invocation.method(#sendPasswordResetEmail, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));
      await expectLater(
        repository.sendPasswordResetEmail('nope'),
        throwsA(_failureWithCode('invalid-email')),
      );
    });

    test('sendEmailVerification requires a signed-in user', () async {
      await expectLater(
        repository.sendEmailVerification(),
        throwsA(_failureWithCode('no-current-user')),
      );
      await repository.signInWithEmail(email: 'ann@example.com', password: 'p');
      await repository.sendEmailVerification();
    });

    test('signInWithGoogle exchanges the Google ID token', () async {
      when(() => google.authenticate()).thenAnswer((_) async => 'google-token');

      await repository.signInWithGoogle();

      expect(repository.currentUser?.uid, 'uid-1');
    });

    test('signInWithGoogle propagates cancellation untouched', () async {
      when(() => google.authenticate())
          .thenThrow(const AuthFailure.cancelled());

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<AuthFailure>().having((f) => f.isCancelled, 'c', isTrue)),
      );
      expect(repository.currentUser, isNull);
    });

    test(
      'signInWithApple sends the hashed nonce and stores the name',
      () async {
        auth = MockFirebaseAuth(mockUser: MockUser(uid: 'apple-uid'));
        repository = repositoryWith(auth);
        when(
          () => apple.requestCredential(hashedNonce: any(named: 'hashedNonce')),
        ).thenAnswer((_) async => _appleCredential);

        await repository.signInWithApple();

        verify(
          () => apple.requestCredential(hashedNonce: sha256OfString(_rawNonce)),
        ).called(1);
        expect(repository.currentUser?.uid, 'apple-uid');
        expect(repository.currentUser?.displayName, 'Ann Lee');
      },
    );

    test('signInWithApple keeps an existing display name', () async {
      auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'apple-uid', displayName: 'Existing'),
      );
      repository = repositoryWith(auth);
      when(
        () => apple.requestCredential(hashedNonce: any(named: 'hashedNonce')),
      ).thenAnswer((_) async => _appleCredential);

      await repository.signInWithApple();

      expect(repository.currentUser?.displayName, 'Existing');
    });

    test('unexpected errors become AuthFailure.unknown', () async {
      when(() => google.authenticate()).thenThrow(StateError('boom'));

      await expectLater(
        repository.signInWithGoogle(),
        throwsA(_failureWithCode('unknown')),
      );
    });
  });

  group('with strict mocks', () {
    late MockFirebaseAuthStrict auth;
    late MockFirebaseUser user;
    late FirebaseAuthRepository repository;

    void givenProviders(List<String> providerIds) {
      when(() => user.providerData)
          .thenReturn([for (final id in providerIds) FakeUserInfo(id)]);
    }

    setUp(() {
      auth = MockFirebaseAuthStrict();
      user = MockFirebaseUser();
      repository = repositoryWith(auth);
      when(() => auth.currentUser).thenReturn(user);
      when(() => auth.signOut()).thenAnswer((_) async {});
      when(() => user.email).thenReturn('ann@example.com');
      when(() => user.delete()).thenAnswer((_) async {});
      when(() => user.reauthenticateWithCredential(any()))
          .thenAnswer((_) async => FakeUserCredential());
    });

    test('signOut also signs out of Google for Google users', () async {
      givenProviders([AuthProviderIds.google]);

      await repository.signOut();

      verify(() => google.signOut()).called(1);
      verify(() => auth.signOut()).called(1);
    });

    test('signOut skips Google for other users', () async {
      givenProviders([AuthProviderIds.password]);

      await repository.signOut();

      verifyNever(() => google.signOut());
      verify(() => auth.signOut()).called(1);
    });

    test('signOut still signs out of Firebase if Google fails', () async {
      givenProviders([AuthProviderIds.google]);
      when(() => google.signOut()).thenThrow(Exception('plugin error'));

      await repository.signOut();

      verify(() => auth.signOut()).called(1);
    });

    test('deleteAccount re-authenticates password users first', () async {
      givenProviders([AuthProviderIds.password]);

      await repository.deleteAccount(password: 'secret');

      final captured = verify(
        () => user.reauthenticateWithCredential(captureAny()),
      ).captured;
      expect(
        (captured.single as AuthCredential).providerId,
        AuthProviderIds.password,
      );
      verify(() => user.delete()).called(1);
    });

    test('deleteAccount surfaces requires-recent-login', () async {
      givenProviders([AuthProviderIds.password]);
      when(() => user.delete())
          .thenThrow(FirebaseAuthException(code: 'requires-recent-login'));

      await expectLater(
        repository.deleteAccount(),
        throwsA(
          isA<AuthFailure>().having(
            (f) => f.requiresRecentLogin,
            'requiresRecentLogin',
            isTrue,
          ),
        ),
      );
    });

    test('deleteAccount re-authenticates Google users on demand', () async {
      givenProviders([AuthProviderIds.google]);
      var attempts = 0;
      when(() => user.delete()).thenAnswer((_) async {
        if (attempts++ == 0) {
          throw FirebaseAuthException(code: 'requires-recent-login');
        }
      });
      when(() => google.authenticate()).thenAnswer((_) async => 'fresh-token');

      await repository.deleteAccount();

      verify(() => google.authenticate()).called(1);
      verify(() => user.reauthenticateWithCredential(any())).called(1);
      verify(() => user.delete()).called(2);
      verify(() => google.disconnect()).called(1);
    });

    test('deleteAccount revokes Apple tokens before deleting', () async {
      givenProviders([AuthProviderIds.apple]);
      when(
        () => apple.requestCredential(hashedNonce: any(named: 'hashedNonce')),
      ).thenAnswer((_) async => _appleCredential);
      when(() => auth.revokeTokenWithAuthorizationCode(any()))
          .thenAnswer((_) async {});

      await repository.deleteAccount();

      verifyInOrder([
        () => user.reauthenticateWithCredential(any()),
        () => auth.revokeTokenWithAuthorizationCode('apple-auth-code'),
        () => user.delete(),
      ]);
    });
  });
}
