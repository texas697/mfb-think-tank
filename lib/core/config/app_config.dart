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
  });

  /// Reads the values compiled in via `--dart-define(-from-file)`.
  const AppConfig.fromEnvironment()
    : googleServerClientId = const String.fromEnvironment(
        'GOOGLE_SERVER_CLIENT_ID',
      ),
      googleIosClientId = const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// The Firebase project's "Web client" OAuth client id.
  ///
  /// Required on Android so Google Sign-In returns an ID token that Firebase
  /// accepts. Optional on iOS.
  final String googleServerClientId;

  /// `CLIENT_ID` from `ios/Runner/GoogleService-Info.plist`.
  final String googleIosClientId;

  /// Whether the ids Google Sign-In needs on [platform] are present.
  bool isGoogleSignInConfiguredFor(TargetPlatform platform) =>
      switch (platform) {
        TargetPlatform.android => googleServerClientId.isNotEmpty,
        TargetPlatform.iOS => googleIosClientId.isNotEmpty,
        _ => false,
      };
}

/// The app's [AppConfig]. Override in tests.
final appConfigProvider = Provider<AppConfig>(
  (ref) => const AppConfig.fromEnvironment(),
);
