import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/data/backend_id_token_provider.dart';
import 'package:mfb_think_tank/features/auth/data/backend_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _base = 'https://api.example.com';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BackendSession session;

  BackendIdTokenProvider tokensFor(MockClient client) {
    session = BackendSession(http: client, baseUrl: Uri.parse(_base));
    return BackendIdTokenProvider(session: session);
  }

  Future<void> signIn(String token, {String refreshToken = 'ref'}) =>
      session.setSignedIn(
        token: token,
        refreshToken: refreshToken,
        user: const AppUser(uid: 'u1'),
      );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('throws StateError when nobody is signed in', () async {
    final tokens = tokensFor(MockClient((_) async => http.Response('', 200)));

    await expectLater(tokens.getIdToken(), throwsStateError);
  });

  test('returns the current token once signed in', () async {
    final tokens = tokensFor(MockClient((_) async => http.Response('', 200)));
    await signIn('tok');

    expect(await tokens.getIdToken(), 'tok');
  });

  test('forceRefresh rotates the token via POST /api/auth/refresh', () async {
    late http.Request seen;
    final tokens = tokensFor(
      MockClient((request) async {
        seen = request;
        return http.Response('{"token":"fresh","refreshToken":"ref2"}', 200);
      }),
    );
    await signIn('stale', refreshToken: 'ref1');

    expect(await tokens.getIdToken(forceRefresh: true), 'fresh');
    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/auth/refresh');
    expect(jsonDecode(seen.body), {'refreshToken': 'ref1'});
    expect(session.currentToken, 'fresh');
  });

  test('forceRefresh throws StateError when signed out', () async {
    final tokens = tokensFor(MockClient((_) async => http.Response('{}', 200)));

    await expectLater(tokens.getIdToken(forceRefresh: true), throwsStateError);
  });

  test(
    'forceRefresh throws StateError when the server rejects the token',
    () async {
      final tokens = tokensFor(
        MockClient((_) async => http.Response('{"error":"expired"}', 401)),
      );
      await signIn('stale', refreshToken: 'ref1');

      await expectLater(
        tokens.getIdToken(forceRefresh: true),
        throwsStateError,
      );
    },
  );
}
