import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/features/auth/application/api_client_providers.dart';
import 'package:mfb_think_tank/features/auth/data/account_deletion_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/auth/data/backend_auth_repository.dart';

/// The platform the app runs on. Override in tests.
final targetPlatformProvider = Provider<TargetPlatform>(
  (ref) => defaultTargetPlatform,
);

final accountDeletionGatewayProvider = Provider<AccountDeletionGateway>(
  // Read lazily: the API client needs a configured base URL, which plain
  // sign-in never does.
  (ref) => HttpAccountDeletionGateway(api: () => ref.read(apiClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return createBackendAuthRepository(
    session: ref.watch(backendSessionProvider),
    http: ref.watch(httpClientProvider),
    baseUrl: Uri.parse(config.crucixApiBaseUrl),
    deletion: ref.watch(accountDeletionGatewayProvider),
  );
});

/// Signed-in user, updated on sign-in/out only. Drives routing.
final authStateChangesProvider = StreamProvider<AppUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

/// Signed-in user, also updated on profile changes. Use for display.
final currentUserProvider = StreamProvider<AppUser?>(
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

/// The FOSS build drops the Google and Apple SDKs, so neither button shows.
/// Both options stay off on every platform; the buttons hide themselves.
final socialSignInOptionsProvider = Provider<SocialSignInOptions>(
  (ref) => const SocialSignInOptions(
    showGoogle: false,
    googleConfigured: false,
    showApple: false,
  ),
);
