import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';

void main() {
  group('AuthFailure.fromFirebase', () {
    test('keeps the Firebase code', () {
      final failure = AuthFailure.fromFirebase(
        FirebaseAuthException(code: 'email-already-in-use'),
      );
      expect(failure.code, 'email-already-in-use');
      expect(failure.message, 'An account already exists for that email.');
    });

    test('does not reveal which of email/password was wrong', () {
      for (final code in [
        'user-not-found',
        'wrong-password',
        'invalid-credential',
        'INVALID_LOGIN_CREDENTIALS',
      ]) {
        expect(
          AuthFailure.messageForCode(code),
          'Incorrect email or password.',
          reason: code,
        );
      }
    });

    test('maps common codes to specific messages', () {
      expect(
        AuthFailure.messageForCode('network-request-failed'),
        contains('Network error'),
      );
      expect(
        AuthFailure.messageForCode('too-many-requests'),
        contains('Too many attempts'),
      );
      expect(
        AuthFailure.messageForCode('operation-not-allowed'),
        contains('Firebase console'),
      );
    });

    test('falls back to a generic message for unknown codes', () {
      expect(
        AuthFailure.messageForCode('something-new'),
        'Something went wrong. Please try again.',
      );
    });
  });

  test('flags', () {
    expect(const AuthFailure.cancelled().isCancelled, isTrue);
    expect(const AuthFailure.unknown().isCancelled, isFalse);
    expect(
      AuthFailure.fromFirebase(
        FirebaseAuthException(code: 'requires-recent-login'),
      ).requiresRecentLogin,
      isTrue,
    );
  });
}
