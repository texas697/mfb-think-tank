import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mfb_think_tank/features/auth/data/app_user.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';
import 'package:mfb_think_tank/features/auth/data/auth_repository.dart';
import 'package:mfb_think_tank/features/auth/data/backend_auth_repository.dart';
import 'package:mfb_think_tank/features/auth/data/backend_session.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/mocks.dart';

const _base = 'https://api.example.com';

const _userJson = <String, Object?>{
  'uid': 'usr_123',
  'email': 'user@example.com',
  'displayName': 'Ada',
  'emailVerified': false,
  'providerIds': ['password'],
};

String _signedIn({
  String token = 'tok',
  String refreshToken = 'ref',
  Map<String, Object?> user = _userJson,
}) => jsonEncode({'token': token, 'refreshToken': refreshToken, 'user': user});

Matcher failureWithCode(String code) =>
    isA<AuthFailure>().having((f) => f.code, 'code', code);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BackendSession session;
  late MockAccountDeletionGateway deletion;

  AuthRepository repository(MockClient client) {
    session = BackendSession(http: client, baseUrl: Uri.parse(_base));
    deletion = MockAccountDeletionGateway();
    when(() => deletion.deleteAccount()).thenAnswer((_) async {});
    return createBackendAuthRepository(
      session: session,
      http: client,
      baseUrl: Uri.parse(_base),
      deletion: deletion,
    );
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('signInWithEmail stores the tokens and maps the user', () async {
    late http.Request seen;
    final repo = repository(
      MockClient((request) async {
        seen = request;
        return http.Response(_signedIn(), 200);
      }),
    );

    await repo.signInWithEmail(email: ' ann@example.com ', password: 'secret');

    expect(seen.method, 'POST');
    expect(seen.url.path, '/api/auth/signin');
    expect(jsonDecode(seen.body), {
      'email': 'ann@example.com',
      'password': 'secret',
    });
    expect(session.currentToken, 'tok');
    expect(repo.currentUser?.uid, 'usr_123');
    expect(repo.currentUser?.displayName, 'Ada');
    expect(repo.currentUser?.hasProvider(AuthProviderIds.password), isTrue);
  });

  test('authStateChanges emits the signed-in user', () async {
    final repo = repository(
      MockClient((_) async => http.Response(_signedIn(), 200)),
    );
    final emitted = <AppUser?>[];
    final sub = repo.authStateChanges().listen(emitted.add);
    addTearDown(sub.cancel);

    await repo.signInWithEmail(email: 'a@b.co', password: 'pw');
    await pumpEventQueue();

    expect(emitted.last?.uid, 'usr_123');
  });

  test(
    'signUpWithEmail posts the display name and stores the session',
    () async {
      late http.Request seen;
      final repo = repository(
        MockClient((request) async {
          seen = request;
          return http.Response(_signedIn(), 200);
        }),
      );

      await repo.signUpWithEmail(
        email: 'ada@example.com',
        password: 'abcd1234',
        displayName: '  Ada Lovelace ',
      );

      expect(seen.url.path, '/api/auth/signup');
      expect(jsonDecode(seen.body), {
        'email': 'ada@example.com',
        'password': 'abcd1234',
        'displayName': 'Ada Lovelace',
      });
      expect(session.currentToken, 'tok');
    },
  );

  test('maps a server error code to the matching AuthFailure', () async {
    final repo = repository(
      MockClient(
        (_) async => http.Response(
          '{"error":{"code":"wrong-password","message":"nope"}}',
          401,
        ),
      ),
    );

    await expectLater(
      repo.signInWithEmail(email: 'a@b.co', password: 'bad'),
      throwsA(
        isA<AuthFailure>()
            .having((f) => f.code, 'code', 'wrong-password')
            .having(
              (f) => f.message,
              'message',
              'Incorrect email or password.',
            ),
      ),
    );
    expect(session.currentToken, isNull);
  });

  test(
    'falls back to the status code when the body has no error code',
    () async {
      final repo = repository(MockClient((_) async => http.Response('', 429)));

      await expectLater(
        repo.signInWithEmail(email: 'a@b.co', password: 'x'),
        throwsA(failureWithCode('too-many-requests')),
      );
    },
  );

  test('maps a transport failure to network-request-failed', () async {
    final repo = repository(
      MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(
      repo.signInWithEmail(email: 'a@b.co', password: 'x'),
      throwsA(
        isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          'network-request-failed',
        ),
      ),
    );
  });

  test('signOut clears the session and emits null', () async {
    final repo = repository(
      MockClient((_) async => http.Response(_signedIn(), 200)),
    );
    await repo.signInWithEmail(email: 'a@b.co', password: 'pw');

    final emitted = <AppUser?>[];
    final sub = repo.authStateChanges().listen(emitted.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await repo.signOut();
    await pumpEventQueue();

    expect(session.currentToken, isNull);
    expect(repo.currentUser, isNull);
    expect(emitted.last, isNull);
  });

  test('reloadUser GETs /api/me with the bearer token', () async {
    late http.Request seen;
    final repo = repository(
      MockClient((request) async {
        seen = request;
        return http.Response(
          jsonEncode({..._userJson, 'emailVerified': true}),
          200,
        );
      }),
    );
    await session.setSignedIn(
      token: 'tok',
      refreshToken: 'ref',
      user: const AppUser(uid: 'usr_123'),
    );

    await repo.reloadUser();

    expect(seen.method, 'GET');
    expect(seen.url.path, '/api/me');
    expect(seen.headers['Authorization'], 'Bearer tok');
    expect(repo.currentUser?.emailVerified, isTrue);
  });

  test('reloadUser throws no-current-user when signed out', () async {
    final repo = repository(MockClient((_) async => http.Response('{}', 200)));

    await expectLater(
      repo.reloadUser(),
      throwsA(failureWithCode('no-current-user')),
    );
  });

  test('deleteAccount deletes server-side then clears the session', () async {
    final repo = repository(
      MockClient((_) async => http.Response(_signedIn(), 200)),
    );
    await session.setSignedIn(
      token: 'tok',
      refreshToken: 'ref',
      user: const AppUser(uid: 'usr_123'),
    );

    await repo.deleteAccount(password: 'secret');

    verify(() => deletion.deleteAccount()).called(1);
    expect(session.currentToken, isNull);
    expect(repo.currentUser, isNull);
  });

  test('sendPasswordResetEmail posts the email', () async {
    late http.Request seen;
    final repo = repository(
      MockClient((request) async {
        seen = request;
        return http.Response('', 204);
      }),
    );

    await repo.sendPasswordResetEmail(' ada@example.com ');

    expect(seen.url.path, '/api/auth/reset-password');
    expect(jsonDecode(seen.body), {'email': 'ada@example.com'});
  });

  test('sendEmailVerification posts with the bearer token', () async {
    late http.Request seen;
    final repo = repository(
      MockClient((request) async {
        seen = request;
        return http.Response('', 204);
      }),
    );
    await session.setSignedIn(
      token: 'tok',
      refreshToken: 'ref',
      user: const AppUser(uid: 'usr_123'),
    );

    await repo.sendEmailVerification();

    expect(seen.url.path, '/api/auth/verify-email');
    expect(seen.headers['Authorization'], 'Bearer tok');
  });

  test('Google and Apple sign-in are unsupported in this build', () async {
    final repo = repository(MockClient((_) async => http.Response('{}', 200)));

    await expectLater(
      repo.signInWithGoogle(),
      throwsA(failureWithCode('unsupported')),
    );
    await expectLater(
      repo.signInWithApple(),
      throwsA(failureWithCode('unsupported')),
    );
  });
}
