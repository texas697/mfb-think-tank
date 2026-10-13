import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:mfb_think_tank/features/auth/data/account_deletion_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/apple_sign_in_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';
import 'package:mfb_think_tank/features/auth/data/google_sign_in_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/nonce.dart';

/// Firebase provider ids as they appear in `User.providerData`.
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
  Stream<User?> authStateChanges();

  /// Emits on sign-in, sign-out and profile changes (e.g. display name).
  Stream<User?> userChanges();

  User? get currentUser;

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
  /// Password users pass their [password] to confirm their identity. Apple
  /// users are re-authenticated so their tokens can be revoked, as required
  /// by App Store Review Guideline 5.1.1(v). The server then deletes the
  /// user's data and the Auth user; the local session is cleared afterwards.
  Future<void> deleteAccount({String? password});
}

/// [AuthRepository] backed by Firebase Authentication.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this._auth,
    required this._google,
    required this._apple,
    required this._deletion,
    @visibleForTesting String Function()? nonceGenerator,
  }) : _generateNonce = nonceGenerator ?? generateNonce;

  final FirebaseAuth _auth;
  final GoogleSignInGateway _google;
  final AppleSignInGateway _apple;
  final AccountDeletionGateway _deletion;
  final String Function() _generateNonce;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Stream<User?> userChanges() => _auth.userChanges();

  @override
  User? get currentUser => _auth.currentUser;

  User get _requireUser =>
      _auth.currentUser ??
      (throw const AuthFailure('no-current-user', 'You are not signed in.'));

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return;
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await user.updateDisplayName(name);
    }
    await user.sendEmailVerification();
  });

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> sendEmailVerification() =>
      _guard(() => _requireUser.sendEmailVerification());

  @override
  Future<void> reloadUser() => _guard(() => _requireUser.reload());

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    final idToken = await _google.authenticate();
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  });

  @override
  Future<void> signInWithApple() => _guard(() async {
    final (:credential, :apple) = await _appleCredential();
    final result = await _auth.signInWithCredential(credential);

    // Apple shares the user's name only on the first sign-in, and Firebase
    // does not store it automatically.
    final user = result.user;
    final name = apple.fullName;
    if (user != null && name != null && (user.displayName ?? '').isEmpty) {
      await user.updateDisplayName(name);
    }
  });

  @override
  Future<void> signOut() => _guard(() async {
    if (_hasProvider(_auth.currentUser, AuthProviderIds.google)) {
      await _bestEffort(_google.signOut);
    }
    await _auth.signOut();
  });

  @override
  Future<void> deleteAccount({String? password}) => _guard(() async {
    final user = _requireUser;
    final usedGoogle = _hasProvider(user, AuthProviderIds.google);

    if (_hasProvider(user, AuthProviderIds.apple)) {
      // Apple requires revoking its tokens, which needs a fresh
      // authorization code, so always re-authenticate Apple users.
      final (:credential, :apple) = await _appleCredential();
      await user.reauthenticateWithCredential(credential);
      await _auth.revokeTokenWithAuthorizationCode(apple.authorizationCode);
    } else if (password != null && user.email != null) {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    }

    // The server wipes Firestore data and the Auth user together, so a
    // local `user.delete()` is neither needed nor safe (it would strand data).
    await _deletion.deleteAccount();

    if (usedGoogle) await _bestEffort(_google.disconnect);
    // Clears the locally cached session; the account itself is already gone.
    await _bestEffort(_auth.signOut);
  });

  Future<({OAuthCredential credential, AppleIdCredential apple})>
  _appleCredential() async {
    final rawNonce = _generateNonce();
    final apple = await _apple.requestCredential(
      hashedNonce: sha256OfString(rawNonce),
    );
    final credential = AppleAuthProvider.credentialWithIDToken(
      apple.identityToken,
      rawNonce,
      AppleFullPersonName(
        givenName: apple.givenName,
        familyName: apple.familyName,
      ),
    );
    return (credential: credential, apple: apple);
  }

  static bool _hasProvider(User? user, String providerId) =>
      user?.providerData.any((p) => p.providerId == providerId) ?? false;

  static Future<void> _bestEffort(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      debugPrint('Ignored error during auth cleanup: $e');
    }
  }

  /// Runs [action] and converts every error into an [AuthFailure].
  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e);
    } on Object catch (e, stack) {
      debugPrint('Unexpected auth error: $e\n$stack');
      throw const AuthFailure.unknown();
    }
  }
}
