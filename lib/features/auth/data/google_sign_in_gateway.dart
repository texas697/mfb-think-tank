import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';

/// Thin seam over `google_sign_in` so the repository can be unit tested.
abstract interface class GoogleSignInGateway {
  /// Runs the interactive Google flow and returns a Google ID token.
  ///
  /// Throws [AuthFailure] (including [AuthFailure.cancelled]).
  Future<String> authenticate();

  /// Signs out of Google so the account picker shows next time.
  Future<void> signOut();

  /// Signs out and revokes this app's Google grants (used on account delete).
  Future<void> disconnect();
}

/// [GoogleSignInGateway] backed by `google_sign_in` 7.x.
class GoogleSignInPluginGateway implements GoogleSignInGateway {
  GoogleSignInPluginGateway({
    required this._config,
    GoogleSignIn? googleSignIn,
    TargetPlatform? platform,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
       _platform = platform ?? defaultTargetPlatform;

  final AppConfig _config;
  final GoogleSignIn _googleSignIn;
  final TargetPlatform _platform;
  Future<void>? _initialization;

  /// `GoogleSignIn.initialize` must be called exactly once per app launch.
  Future<void> _ensureInitialized() async {
    try {
      await (_initialization ??= _googleSignIn.initialize(
        clientId:
            _platform == TargetPlatform.iOS &&
                _config.googleIosClientId.isNotEmpty
            ? _config.googleIosClientId
            : null,
        serverClientId: _config.googleServerClientId.isEmpty
            ? null
            : _config.googleServerClientId,
      ));
    } catch (_) {
      // Allow a retry on the next attempt.
      _initialization = null;
      rethrow;
    }
  }

  @override
  Future<String> authenticate() async {
    if (!_config.isGoogleSignInConfiguredFor(_platform)) {
      throw const AuthFailure(
        'google-not-configured',
        'Google Sign-In is not configured. '
            'Fill in config/app_config.json and rebuild.',
      );
    }
    try {
      await _ensureInitialized();
      if (!_googleSignIn.supportsAuthenticate()) {
        throw const AuthFailure(
          'google-unsupported',
          'Google Sign-In is not supported on this platform.',
        );
      }
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'google-missing-id-token',
          'Google did not return an ID token. '
              'Check GOOGLE_SERVER_CLIENT_ID in config/app_config.json.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (e) {
      // On Android a missing/wrong SHA fingerprint in Firebase often surfaces
      // as "canceled" (e.g. "[16] Account reauth failed"); log the details.
      debugPrint('GoogleSignInException ${e.code}: ${e.description}');
      throw mapGoogleSignInException(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }

  @override
  Future<void> disconnect() async {
    await _ensureInitialized();
    await _googleSignIn.disconnect();
  }
}

/// Maps a [GoogleSignInException] to an [AuthFailure].
@visibleForTesting
AuthFailure mapGoogleSignInException(GoogleSignInException e) =>
    switch (e.code) {
      // Only a genuine user cancel is silent. interrupted / uiUnavailable are
      // real failures and must be shown.
      GoogleSignInExceptionCode.canceled => const AuthFailure.cancelled(),
      GoogleSignInExceptionCode.clientConfigurationError ||
      GoogleSignInExceptionCode.providerConfigurationError => const AuthFailure(
        'google-configuration-error',
        'Google Sign-In is misconfigured. Check the OAuth client ids and '
            'the SHA fingerprints registered in Firebase.',
      ),
      _ => const AuthFailure(
        'google-sign-in-failed',
        'Google sign-in failed. Please try again.',
      ),
    };
