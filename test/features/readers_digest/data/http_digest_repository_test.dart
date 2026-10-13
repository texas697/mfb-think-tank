import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/data/http_digest_repository.dart';

class _Tokens implements IdTokenProvider {
  @override
  Future<String> getIdToken({bool forceRefresh = false}) async => 't';
}

HttpDigestRepository repo(
  Future<http.Response> Function(http.Request) handler,
) => HttpDigestRepository(
  api: ApiClient(
    http: MockClient(handler),
    base: Uri.parse('https://api.example.com'),
    tokens: _Tokens(),
  ),
);

void main() {
  test('decodes a partial feed defensively', () async {
    final feed = await repo(
      (_) async => http.Response(
        jsonEncode({
          'items': [
            {'id': 'a', 'title': 'T', 'publishedAt': null},
            'junk',
          ],
          'taste': 'bad',
        }),
        200,
      ),
    ).fetchFeed(const DigestQuery());
    expect(feed.items.single.id, 'a');
    expect(feed.items.single.publishedAt, isNull);
    expect(feed.taste.isEmpty, isTrue);
    expect(feed.mode, 'chrono');
  });

  test('sends the sanitized query', () async {
    late Uri url;
    await repo((request) async {
      url = request.url;
      return http.Response('{}', 200);
    }).fetchFeed(
      DigestQuery.sanitized(filter: 'bogus', topic: 'ai-policy', q: 'x' * 150),
    );
    expect(url.queryParameters['filter'], isNull);
    expect(url.queryParameters['topic'], 'ai-policy');
    expect(url.queryParameters['q'], hasLength(100));
    expect(url.queryParameters['limit'], '300');
  });

  test('maps status codes to feature failures', () async {
    Future<Object?> failure(int status, [String body = '{}']) async {
      try {
        await repo((_) async => http.Response(body, status)).fetchArticle('a');
      } on Object catch (e) {
        return e;
      }
      return null;
    }

    expect(await failure(401), isA<DigestUnauthenticated>());
    expect(await failure(403), isA<DigestForbidden>());
    expect(await failure(404), isA<DigestNotFound>());
    expect(
      await failure(422, '{"error":"too short"}'),
      isA<DigestInsufficientText>(),
    );
    expect(
      await failure(400, '{"error":"No LLM configured"}'),
      isA<DigestMissingAiSettings>(),
    );
    expect(await failure(503), isA<DigestUnavailable>());
    expect(await failure(200, 'not json'), isA<DigestMalformed>());
  });

  test('maps transport failures', () async {
    await expectLater(
      repo((_) async => throw http.ClientException('x'))
          .fetchFeed(const DigestQuery()),
      throwsA(isA<DigestNetwork>()),
    );
  });

  test('a rating returns the server value and is never retried', () async {
    var calls = 0;
    final rating = await repo((request) async {
      calls++;
      expect(jsonDecode(request.body), {'rating': 1});
      return http.Response('{"rating":1}', 200);
    }).sendRating('a', 1);
    expect(rating, 1);
    expect(calls, 1);
    var failedCalls = 0;
    await expectLater(
      repo((_) async {
        failedCalls++;
        return http.Response('{}', 500);
      }).sendRating('a', 1),
      throwsA(isA<DigestFailure>()),
    );
    expect(failedCalls, 1);
  });
}
