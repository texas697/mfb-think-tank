import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/features/telegram/data/http_telegram_repository.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_failure.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_paths.dart';

class _Tokens implements IdTokenProvider {
  final calls = <bool>[];
  @override
  Future<String> getIdToken({bool forceRefresh = false}) async {
    calls.add(forceRefresh);
    return forceRefresh ? 'fresh' : 'initial';
  }
}

void main() {
  late _Tokens tokens;
  HttpTelegramRepository repository(
    Future<http.Response> Function(http.Request) handler,
  ) {
    tokens = _Tokens();
    final base = Uri.parse('https://api.example/');
    return HttpTelegramRepository(
      api: ApiClient(http: MockClient(handler), base: base, tokens: tokens),
      base: base,
      tokens: tokens,
    );
  }

  test(
    'disconnected is a valid status; channels preserve server group metadata',
    () async {
      final repo = repository((request) async {
        expect(request.headers['Authorization'], 'Bearer initial');
        if (request.url.path.endsWith('status')) {
          return http.Response(
            '''{"configured":true,"authenticated":true,"connected":false}''',
            200,
          );
        }
        expect(request.url.queryParameters['limit'], '200');
        return http.Response(
          jsonEncode({
            'dialogs': [
              {
                'id': '-1001',
                'title': 'Channel',
                'group': 'Iran',
                'hasPhoto': true,
                'unreadCount': 5,
              },
            ],
          }),
          200,
        );
      });
      expect((await repo.fetchStatus()).canRead, isFalse);
      final dialog = (await repo.fetchDialogs()).single;
      expect(dialog.group, 'Iran');
      expect(dialog.hasPhoto, isTrue);
      expect(dialog.unreadCount, 5);
    },
  );
  test(
    'messages retain original, translation, webpage and media metadata',
    () async {
      final repo = repository((request) async {
        expect(request.url.path, '/api/telegram/messages/-1001');
        expect(request.url.queryParameters['limit'], '100');
        return http.Response(
          jsonEncode({
            'messages': [
              {
                'id': 2,
                'text': 'original',
                'out': false,
                'date': '2026-10-15T12:00:00Z',
                'translation': {'text': 'English', 'from': 'fa'},
                'media': {
                  'kind': 'video',
                  'mime': 'video/mp4',
                  'tooLarge': false,
                  'size': 100,
                },
                'webpage': {'url': 'https://example.com', 'hasPhoto': true},
              },
            ],
          }),
          200,
        );
      });
      final message = (await repo.fetchMessages('-1001')).single;
      expect(message.translation?.text, 'English');
      expect(message.text, 'original');
      expect(message.media?.canPlay, isTrue);
      expect(message.webpage?.hasPhoto, isTrue);
    },
  );
  test(
    'private image retries once with a fresh token and never a token URL',
    () async {
      var count = 0;
      final repo = repository((request) async {
        expect(request.url.queryParameters, {'kind': 'photo'});
        expect(request.url.toString(), isNot(contains('Bearer')));
        expect(
          request.headers['Authorization'],
          count == 0 ? 'Bearer initial' : 'Bearer fresh',
        );
        return count++ == 0
            ? http.Response('', 401)
            : http.Response.bytes(
                [1, 2, 3],
                200,
                headers: {'content-type': 'image/jpeg'},
              );
      });
      expect(await repo.fetchImage(TelegramPaths.media('-1001', 2, 'photo')), [
        1,
        2,
        3,
      ]);
      expect(tokens.calls, [false, true]);
    },
  );
  test('two unauthorized responses do not cause a retry loop', () async {
    final repo = repository((_) async => http.Response('{}', 401));
    await expectLater(
      repo.fetchDialogs(),
      throwsA(
        isA<TelegramFailure>().having((e) => e.statusCode, 'status', 401),
      ),
    );
    expect(tokens.calls, [false, true]);
  });
  for (final status in [403, 404, 429, 500]) {
    test(
      'HTTP $status is an explicit failure rather than an empty list',
      () async {
        final repo = repository((_) async => http.Response('{}', status));
        await expectLater(
          repo.fetchMessages('-1'),
          throwsA(
            isA<TelegramFailure>().having(
              (e) => e.statusCode,
              'status',
              status,
            ),
          ),
        );
      },
    );
  }
  test(
    'malformed messages and wrong image MIME are feature failures',
    () async {
      final repo = repository(
        (_) async =>
            http.Response('{}', 200, headers: {'content-type': 'text/html'}),
      );
      await expectLater(
        repo.fetchMessages('-1'),
        throwsA(isA<TelegramFailure>()),
      );
      await expectLater(
        repo.fetchImage(TelegramPaths.avatar('-1')),
        throwsA(isA<TelegramFailure>()),
      );
    },
  );
  test(
    'private media cannot send credentials to an arbitrary origin or path',
    () async {
      var calls = 0;
      final repo = repository((_) async {
        calls++;
        return http.Response('', 200);
      });
      await expectLater(
        repo.fetchImage('https://evil.example/api/telegram/avatar/1'),
        throwsA(isA<TelegramFailure>()),
      );
      await expectLater(
        repo.fetchImage('api/me'),
        throwsA(isA<TelegramFailure>()),
      );
      expect(calls, 0);
      expect(
        repo.mediaUri(TelegramPaths.media('-1', 2, 'file')).toString(),
        'https://api.example/api/telegram/media/-1/2?kind=file',
      );
    },
  );
}
