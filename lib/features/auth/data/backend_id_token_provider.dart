import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/features/auth/data/backend_session.dart';

/// [IdTokenProvider] backed by the Crucix [BackendSession].
///
/// Signs out by throwing [StateError], the contract the API client relies on
/// to report an unauthorized call.
class BackendIdTokenProvider implements IdTokenProvider {
  BackendIdTokenProvider({required this._session});

  final BackendSession _session;

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      // Exchanges the refresh token for a fresh access token, per the
      // contract's POST /api/auth/refresh.
      await _session.refresh();
    }
    final token = _session.currentToken;
    if (token == null || token.isEmpty) {
      throw StateError('No signed-in user');
    }
    return token;
  }
}
