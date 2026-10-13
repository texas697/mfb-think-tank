import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/auth/application/api_client_providers.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_repository.dart';
import 'package:mfb_think_tank/features/readers_digest/data/http_digest_repository.dart';

/// The signed-in user's uid, or null. Digest providers watch this so a user
/// change discards the previous user's state.
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateChangesProvider).value?.uid,
);

/// Digest API contract over HTTP.
final digestRepositoryProvider = Provider<DigestRepository>(
  (ref) => HttpDigestRepository(api: ref.watch(apiClientProvider)),
);
