import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_repository.dart';
import 'package:mfb_think_tank/features/readers_digest/data/http_digest_repository.dart';

/// The signed-in user's uid, or null. Digest providers watch this so a user
/// change discards the previous user's state.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateChangesProvider).value?.uid,
);

/// `package:http` client seam so tests can inject fakes.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Token gateway used by the API client.
final idTokenProvider = Provider<IdTokenProvider>(
  (ref) => FirebaseAuthIdTokenProvider(auth: ref.watch(firebaseAuthProvider)),
);

/// Authenticated Crucix API transport.
final apiClientProvider = Provider<ApiClient>((ref) {
  final base = ref.watch(appConfigProvider).crucixApiBaseUrl;
  if (base.isEmpty) {
    throw StateError('CRUCIX_API_BASE_URL is not configured');
  }
  return ApiClient(
    http: ref.watch(httpClientProvider),
    base: Uri.parse(base),
    tokens: ref.watch(idTokenProvider),
  );
});

/// Digest API contract over HTTP.
final digestRepositoryProvider = Provider<DigestRepository>(
  (ref) => HttpDigestRepository(api: ref.watch(apiClientProvider)),
);
