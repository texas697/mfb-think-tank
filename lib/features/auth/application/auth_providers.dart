import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/features/auth/application/api_client_providers.dart';
import 'package:mfb_think_tank/features/auth/data/account_deletion_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/apple_sign_in_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/auth/data/google_sign_in_gateway.dart';

/// The platform the app runs on. Override in tests.
final targetPlatformProvider = Provider<TargetPlatform>(
  (ref) => defaultTargetPlatform,
);

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

final googleSignInGatewayProvider = Provider<GoogleSignInGateway>(
  (ref) => GoogleSignInPluginGateway(
    config: ref.watch(appConfigProvider),
    platform: ref.watch(targetPlatformProvider),
  ),
);

final appleSignInGatewayProvider = Provider<AppleSignInGateway>(
  (ref) => const SignInWithAppleGateway(),
);

final accountDeletionGatewayProvider = Provider<AccountDeletionGateway>(
  // Read lazily: the API client needs a configured base URL, which plain
  // sign-in never does.
  (ref) => HttpAccountDeletionGateway(api: () => ref.read(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    google: ref.watch(googleSignInGatewayProvider),
    apple: ref.watch(appleSignInGatewayProvider),
    deletion: ref.watch(accountDeletionGatewayProvider),
  ),
);

/// Signed-in user, updated on sign-in/out only. Drives routing.
final authStateChangesProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Signed-in user, also updated on profile changes. Use for display.
final currentUserProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// Which social sign-in buttons to show, based on platform and config.
@immutable
class SocialSignInOptions {
  const SocialSignInOptions({
    required this.showGoogle,
    required this.googleConfigured,
    required this.showApple,
  });

  /// Google Sign-In is supported on this platform.
  final bool showGoogle;

  /// The client ids Google Sign-In needs are present in `app_config.json`.
  final bool googleConfigured;

  /// Sign in with Apple is offered (iOS only).
  final bool showApple;
}

final socialSignInOptionsProvider = Provider<SocialSignInOptions>((ref) {
  final platform = ref.watch(targetPlatformProvider);
  final config = ref.watch(appConfigProvider);
  final isMobile =
      !kIsWeb &&
      (platform == TargetPlatform.android || platform == TargetPlatform.iOS);
  return SocialSignInOptions(
    showGoogle: isMobile,
    googleConfigured: config.isGoogleSignInConfiguredFor(platform),
    showApple: !kIsWeb && platform == TargetPlatform.iOS,
  );
});
