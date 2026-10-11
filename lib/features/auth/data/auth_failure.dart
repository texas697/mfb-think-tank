import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// A user-presentable authentication error.
///
/// Every [AuthRepository] method throws only [AuthFailure], so the UI never has
/// to know about Firebase, Google or Apple exception types.
@immutable
class AuthFailure implements Exception {
  const AuthFailure(this.code, this.message);

  /// Maps a [FirebaseAuthException] to a friendly message.
  factory AuthFailure.fromFirebase(FirebaseAuthException e) =>
      AuthFailure(e.code, messageForCode(e.code));

  /// The user dismissed a sign-in sheet. The UI should stay silent.
  const AuthFailure.cancelled() : this(cancelledCode, 'Sign-in was cancelled.');

  /// A catch-all for unexpected errors.
  const AuthFailure.unknown([String message = _genericMessage])
    : this('unknown', message);

  static const cancelledCode = 'cancelled';
  static const _genericMessage = 'Something went wrong. Please try again.';

  /// Stable error code (Firebase codes are passed through unchanged).
  final String code;

  /// Message suitable for showing to the user.
  final String message;

  bool get isCancelled => code == cancelledCode;

  /// True when the operation needs the user to sign in again first.
  bool get requiresRecentLogin => code == 'requires-recent-login';

  /// User-friendly text for a Firebase Auth error [code].
  static String messageForCode(String code) => switch (code) {
    'invalid-email' => 'That email address looks invalid.',
    'missing-email' => 'Please enter your email address.',
    'missing-password' => 'Please enter your password.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' ||
    'invalid-login-credentials' => 'Incorrect email or password.',
    'email-already-in-use' => 'An account already exists for that email.',
    'weak-password' => 'Please choose a stronger password.',
    'password-does-not-meet-requirements' =>
      'That password does not meet the requirements.',
    'operation-not-allowed' =>
      'This sign-in method is not enabled. '
          'Enable it in the Firebase console under Authentication.',
    'too-many-requests' =>
      'Too many attempts. Please wait a moment and try again.',
    'network-request-failed' =>
      'Network error. Check your connection and try again.',
    'requires-recent-login' =>
      'For your security, please sign in again to continue.',
    'account-exists-with-different-credential' =>
      'An account already exists with this email using a different '
          'sign-in method. Sign in with that method instead.',
    'credential-already-in-use' =>
      'This credential is already linked to another account.',
    'user-mismatch' => 'Please sign in with the same account.',
    'user-token-expired' ||
    'invalid-user-token' => 'Your session expired. Please sign in again.',
    'expired-action-code' => 'This link has expired. Request a new one.',
    'invalid-action-code' => 'This link is invalid or was already used.',
    'no-current-user' => 'You are not signed in.',
    'internal-error' => _genericMessage,
    _ => _genericMessage,
  };

  @override
  bool operator ==(Object other) =>
      other is AuthFailure && other.code == code && other.message == message;

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() => 'AuthFailure($code): $message';
}
