// PLACEHOLDER. This file is overwritten by `flutterfire configure`.
//
// Run `scripts/configure_firebase.sh` from the project root to connect this
// app to your Firebase project. That script generates the real
// `DefaultFirebaseOptions`, `android/app/google-services.json` and
// `ios/Runner/GoogleService-Info.plist`. Commit all three files.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Placeholder until `flutterfire configure` generates the real options.
///
/// [main] catches the [UnsupportedError] thrown here and shows a setup screen
/// instead of crashing.
class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  /// Always throws: Firebase has not been configured for this app yet.
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'Firebase is not configured for this app yet.\n\n'
      'From the project root, run:\n'
      '  scripts/configure_firebase.sh\n\n'
      'It runs `flutterfire configure` and regenerates '
      'lib/firebase_options.dart, then restart the app.',
    );
  }
}
