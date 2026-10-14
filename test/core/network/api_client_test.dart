import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';

class _Tokens implements IdTokenProvider {
  final requests = <bool>[];

  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    requests.add(forceRefresh);
    return forceRefresh ? 'fresh' : 'stale';
  }
}

class _ThrowingTokens implements IdTokenProvider {
  _ThrowingTokens(this.error);

  final Object error;

  @override
  Future<String> getIdToken({bool forceRefresh = false}) =>
      Future<String>.error(error);
}

void main() {
  final base = Uri.parse('https://api.example.com');

  Matcher throwsKind(ApiFailureKind kind) =>
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', kind));

  test('maps a token fetch failure to an ApiException', () async {
    var calls = 0;
    ApiClient client(Object error) => ApiClient(
      http: MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
      base: base,
      tokens: _ThrowingTokens(error),
    );
    await expectLater(
      client(StateError('No signed-in user')).get('api/me'),
      throwsKind(ApiFailureKind.unauthorized),
    );
    // Any token-source exception (for example a network error) must not
    // escape as its own type; repositories only know ApiException.
    await expectLater(
      client(Exception('firebase_auth/network-request-failed')).get('api/me'),
      throwsKind(ApiFailureKind.network),
    );
    expect(calls, 0);
  });

  test('sends the Bearer token and joins path and query', () async {
    late http.BaseRequest seen;
    final client = ApiClient(
      http: MockClient((request) async {
        seen = request;
        return http.Response('{}', 200);
      }),
      base: base,
      tokens: _Tokens(),
    );
    await client.get('api/digest/list', query: {'filter': 'news'});
    expect(
      seen.url.toString(),
      'https://api.example.com/api/digest/list?filter=news',
    );
    expect(seen.headers['Authorization'], 'Bearer stale');
  });

  test('refreshes the token once on 401 and retries', () async {
    final tokens = _Tokens();
    final auth = <String?>[];
    final client = ApiClient(
      http: MockClient((request) async {
        auth.add(request.headers['Authorization']);
        return http.Response('', auth.length == 1 ? 401 : 200);
      }),
      base: base,
      tokens: tokens,
    );
    final response = await client.get('api/me');
    expect(response.statusCode, 200);
    expect(auth, ['Bearer stale', 'Bearer fresh']);
    expect(tokens.requests, [false, true]);
  });

  test('surfaces a second 401 without retrying again', () async {
    var calls = 0;
    final client = ApiClient(
      http: MockClient((_) async {
        calls++;
        return http.Response('', 401);
      }),
      base: base,
      tokens: _Tokens(),
    );
    expect((await client.get('api/me')).statusCode, 401);
    expect(calls, 2);
  });

  test('maps network failures and timeouts', () async {
    final network = ApiClient(
      http: MockClient((_) async => throw http.ClientException('offline')),
      base: base,
      tokens: _Tokens(),
    );
    await expectLater(
      network.get('x'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.network,
        ),
      ),
    );
    final timeout = ApiClient(
      http: MockClient((_) => Completer<http.Response>().future),
      base: base,
      tokens: _Tokens(),
    );
    await expectLater(
      timeout.get('x', timeout: const Duration(milliseconds: 10)),
      throwsA(
        isA<ApiException>().having(
          (e) => e.kind,
          'kind',
          ApiFailureKind.timeout,
        ),
      ),
    );
  });
}
