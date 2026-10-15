import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';

class _Tokens implements IdTokenProvider {
  @override
  Future<String> getIdToken({bool forceRefresh = false}) async => 'fixture';
}

void main() {
  ApiClient client(http.Client http) => ApiClient(
    http: http,
    base: Uri.parse('https://api.example'),
    tokens: _Tokens(),
  );
  test(
    'binary response enforces declared size before collecting bytes',
    () async {
      final api = client(
        MockClient((_) async => http.Response.bytes([1, 2, 3], 200)),
      );
      await expectLater(
        api.getBytes('media', maxBytes: 2),
        throwsA(
          isA<ApiException>().having(
            (e) => e.kind,
            'kind',
            ApiFailureKind.malformed,
          ),
        ),
      );
    },
  );
  test('response body is covered by timeout, not just headers', () async {
    final pending = StreamController<List<int>>();
    addTearDown(pending.close);
    final api = client(
      MockClient.streaming(
        (_, _) async => http.StreamedResponse(pending.stream, 200),
      ),
    );
    await expectLater(
      api.getBytes('media', timeout: const Duration(milliseconds: 5)),
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
