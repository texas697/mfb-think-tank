import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfb_think_tank/core/network/api_client.dart';
import 'package:mfb_think_tank/core/network/id_token_provider.dart';
import 'package:mfb_think_tank/features/auth/data/account_deletion_gateway.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';

class _Tokens implements IdTokenProvider {
  @override
  Future<String> getIdToken({bool forceRefresh = false}) async => 'token';
}

void main() {
  HttpAccountDeletionGateway gateway(MockClient client) =>
      HttpAccountDeletionGateway(
        api: () => ApiClient(
          http: client,
          base: Uri.parse('https://api.example.com'),
          tokens: _Tokens(),
        ),
      );

  Matcher failsWith(String message) => throwsA(
    isA<AuthFailure>()
        .having((f) => f.code, 'code', HttpAccountDeletionGateway.failureCode)
        .having((f) => f.message, 'message', message),
  );

  test('sends DELETE /api/me with the bearer token', () async {
    late http.BaseRequest seen;
    final client = MockClient((request) async {
      seen = request;
      return http.Response('{"ok":true}', 200);
    });

    await gateway(client).deleteAccount();

    expect(seen.method, 'DELETE');
    expect(seen.url.path, '/api/me');
    expect(seen.headers['Authorization'], 'Bearer token');
  });

  test('surfaces the server error message on failure', () async {
    final client = MockClient(
      (_) async => http.Response(
        '{"error":"Account deletion failed, please retry"}',
        500,
      ),
    );

    await expectLater(
      gateway(client).deleteAccount(),
      failsWith('Account deletion failed, please retry'),
    );
  });

  test('maps transport failures to a retryable AuthFailure', () async {
    final client = MockClient((_) async => throw http.ClientException('down'));

    await expectLater(
      gateway(client).deleteAccount(),
      failsWith(
        'Account deletion failed. Check your connection and try again.',
      ),
    );
  });

  test('does not resolve the API client until deletion is requested', () {
    var built = 0;
    HttpAccountDeletionGateway(
      api: () {
        built++;
        throw StateError('not configured');
      },
    );
    expect(built, 0);
  });
}
