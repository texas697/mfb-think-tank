import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Non-secret runtime configuration injected at build time.
///
/// Values come from `config/app_config.json`, passed to every run/build with
/// `--dart-define-from-file=config/app_config.json`.
@immutable
class AppConfig {
  const AppConfig({
    this.googleServerClientId = '',
    this.googleIosClientId = '',
    this.crucixApiBaseUrl = '',
  });

  /// Reads the values compiled in via `--dart-define(-from-file)`.
  const AppConfig.fromEnvironment()
    : googleServerClientId = const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
      ),
      googleIosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      crucixApiBaseUrl = const String.fromEnvironment('CRUCIX_API_BASE_URL');

  /// The OAuth "Web client" id, used on Android to obtain a Google ID token.
  final String googleServerClientId;

  /// The iOS OAuth client id.
  final String googleIosClientId;

  /// HTTPS origin of the Crucix API (e.g. `https://crucix-....a.run.app`).
  final String crucixApiBaseUrl;

  /// Whether the ids Google Sign-In needs on [platform] are present.
  bool isGoogleSignInConfiguredFor(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.android => googleServerClientId.isNotEmpty,
        TargetPlatform.iOS => googleIosClientId.isNotEmpty,
        _ => false,
      };

  /// Whether a Crucix API base URL is configured.
  bool get hasCrucixApiBaseUrl => crucixApiBaseUrl.isNotEmpty;
}

/// The app's [AppConfig]. Override in tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => const AppConfig.fromEnvironment(),
);
