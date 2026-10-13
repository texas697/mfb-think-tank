import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfb_think_tank/core/config/app_info.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_failure.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';
import 'package:mfb_think_tank/features/feedback/data/http_feedback_repository.dart';

class _Tokens implements IdTokenProvider {
  @override
  Future<String> getIdToken({bool forceRefresh = false}) async => 'token';
}

void main() {
  const report = FeedbackReport(
    category: FeedbackCategory.bug,
    description: 'The list is empty',
    page: '/',
    state: {'filter': 'foryou'},
  );

  HttpFeedbackRepository repo(MockClient client) => HttpFeedbackRepository(
    api: () => ApiClient(
      http: client,
      base: Uri.parse('https://api.example.com'),
      tokens: _Tokens(),
    ),
    appInfo: () async => const AppInfo(platform: 'android', version: '1.2+3'),
  );

  test('posts the report with platform and version', () async {
    late http.BaseRequest seen;
    final client = MockClient((request) async {
      seen = request;
      return http.Response('{"ok":true,"id":"f1"}', 201);
    });

    await repo(client).submit(report);

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/feedback');
    expect(seen.headers['Authorization'], 'Bearer token');
    expect(jsonDecode((seen as http.Request).body), {
      'category': 'bug',
      'description': 'The list is empty',
      'platform': 'android',
      'appVersion': '1.2+3',
      'page': '/',
      'state': {'filter': 'foryou'},
    });
  });

  test('maps 429 to a rate-limit failure with the server text', () async {
    final client = MockClient(
      (_) async => http.Response('{"error":"Too much feedback"}', 429),
    );
    await expectLater(
      repo(client).submit(report),
      throwsA(
        isA<FeedbackRateLimited>().having(
          (f) => f.message,
          'message',
          'Too much feedback',
        ),
      ),
    );
  });

  test('maps 400 to a rejection and transport errors to network', () async {
    final rejected = MockClient(
      (_) async => http.Response('{"error":"Please describe"}', 400),
    );
    await expectLater(
      repo(rejected).submit(report),
      throwsA(isA<FeedbackRejected>()),
    );

    final down = MockClient((_) async => throw http.ClientException('down'));
    await expectLater(
      repo(down).submit(report),
      throwsA(isA<FeedbackNetwork>()),
    );
  });
}
