import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/features/auth/data/backend_id_token_provider.dart';
import 'package:mfb_think_tank/features/auth/data/backend_session.dart';

/// `package:http` client seam so tests can inject fakes.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// The shared token/user session written by the auth repository and read by
/// the ID token provider.
final backendSessionProvider = Provider<BackendSession>((ref) {
  final base = ref.watch(appConfigProvider).crucixApiBaseUrl;
  return BackendSession(
    http: ref.watch(httpClientProvider),
    baseUrl: Uri.parse(base),
  );
});

/// Token gateway used by the API client.
final idTokenProvider = Provider<IdTokenProvider>(
  (ref) => BackendIdTokenProvider(session: ref.watch(backendSessionProvider)),
);

/// Authenticated Crucix API transport. Lives with auth because every call
/// carries the signed-in user's bearer token.
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
