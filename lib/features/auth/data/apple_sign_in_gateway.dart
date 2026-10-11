import 'package:flutter/foundation.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The parts of an Apple ID credential the app needs.
@immutable
class AppleIdCredential {
  const AppleIdCredential({
    required this.identityToken,
    required this.authorizationCode,
    this.givenName,
    this.familyName,
  });

  final String identityToken;

  /// Short-lived code used to revoke Apple tokens when deleting an account.
  final String authorizationCode;

  /// Only provided by Apple on the very first sign-in.
  final String? givenName;
  final String? familyName;

  /// "Given Family", or null when Apple did not share a name.
  String? get fullName {
    final parts = [
      givenName,
      familyName,
    ].whereType<String>().map((p) => p.trim()).where((p) => p.isNotEmpty);
    return parts.isEmpty ? null : parts.join(' ');
  }
}

/// Thin seam over `sign_in_with_apple` so the repository can be unit tested.
abstract interface class AppleSignInGateway {
  /// Shows the native Sign in with Apple sheet.
  ///
  /// [hashedNonce] is the SHA-256 of the raw nonce later given to Firebase.
  /// Throws [AuthFailure] (including [AuthFailure.cancelled]).
  Future<AppleIdCredential> requestCredential({required String hashedNonce});
}

/// [AppleSignInGateway] backed by `sign_in_with_apple` (native, iOS only).
class SignInWithAppleGateway implements AppleSignInGateway {
  const SignInWithAppleGateway();

  @override
  Future<AppleIdCredential> requestCredential({
    required String hashedNonce,
  }) async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) {
        throw const AuthFailure(
          'apple-missing-id-token',
          'Apple did not return an identity token. Please try again.',
        );
      }
      return AppleIdCredential(
        identityToken: identityToken,
        authorizationCode: credential.authorizationCode,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      throw e.code == AuthorizationErrorCode.canceled
          ? const AuthFailure.cancelled()
          : const AuthFailure(
              'apple-sign-in-failed',
              'Sign in with Apple failed. Please try again.',
            );
    } on SignInWithAppleException {
      throw const AuthFailure(
        'apple-sign-in-failed',
        'Sign in with Apple is not available on this device.',
      );
    }
  }
}
