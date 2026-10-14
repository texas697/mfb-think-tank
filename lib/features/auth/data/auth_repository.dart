import 'dart:async';

import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';

/// Provider ids as they appear in the backend `user.providerIds`.
abstract final class AuthProviderIds {
  static const password = 'password';
  static const google = 'google.com';
  static const apple = 'apple.com';
}

/// Everything the app needs from authentication.
///
/// All methods throw [AuthFailure] on error, never provider-specific types.
abstract interface class AuthRepository {
  /// Emits on sign-in and sign-out.
  Stream<AppUser?> authStateChanges();

  /// Emits on sign-in, sign-out and profile changes (e.g. display name).
  Stream<AppUser?> userChanges();

  AppUser? get currentUser;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  /// Creates an account, sets [displayName] if given, and sends a
  /// verification email.
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  });

  Future<void> sendPasswordResetEmail(String email);

  Future<void> sendEmailVerification();

  /// Refreshes the current user (e.g. to pick up `emailVerified`).
  Future<void> reloadUser();

  Future<void> signInWithGoogle();

  /// Native Sign in with Apple. iOS only.
  Future<void> signInWithApple();

  Future<void> signOut();

  /// Permanently deletes the current user's account and server-side data.
  ///
  /// The server deletes the user's data and account; the local session is
  /// cleared afterwards.
  Future<void> deleteAccount({String? password});
}
