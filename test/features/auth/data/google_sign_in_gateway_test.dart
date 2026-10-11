import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';
import 'package:mfb_think_tank/features/auth/data/google_sign_in_gateway.dart';
import 'package:mocktail/mocktail.dart';

class _MockGoogleSignIn extends Mock implements GoogleSignIn {}

class _MockAccount extends Mock implements GoogleSignInAccount {}

void main() {
  late _MockGoogleSignIn googleSignIn;
  late _MockAccount account;

  setUp(() {
    googleSignIn = _MockGoogleSignIn();
    account = _MockAccount();
    when(
      () => googleSignIn.initialize(
        clientId: any(named: 'clientId'),
        serverClientId: any(named: 'serverClientId'),
      ),
    ).thenAnswer((_) async {});
    when(() => googleSignIn.supportsAuthenticate()).thenReturn(true);
    when(() => googleSignIn.authenticate()).thenAnswer((_) async => account);
    when(() => account.authentication)
        .thenReturn(const GoogleSignInAuthentication(idToken: 'id-token'));
  });

  GoogleSignInPluginGateway gateway({
    AppConfig config = const AppConfig(
      googleServerClientId: 'server-id',
      googleIosClientId: 'ios-id',
    ),
    TargetPlatform platform = TargetPlatform.android,
  }) => GoogleSignInPluginGateway(
    config: config,
    googleSignIn: googleSignIn,
    platform: platform,
  );

  test('fails fast with a helpful message when not configured', () async {
    await expectLater(
      gateway(config: const AppConfig()).authenticate(),
      throwsA(
        isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          'google-not-configured',
        ),
      ),
    );
    verifyNever(() => googleSignIn.authenticate());
  });

  test('initializes once with the Android server client id', () async {
    final g = gateway();
    expect(await g.authenticate(), 'id-token');
    await g.authenticate();

    verify(() => googleSignIn.initialize(serverClientId: 'server-id'))
        .called(1);
  });

  test('passes the iOS client id on iOS', () async {
    await gateway(platform: TargetPlatform.iOS).authenticate();

    verify(
      () => googleSignIn.initialize(
        clientId: 'ios-id',
        serverClientId: 'server-id',
      ),
    ).called(1);
  });

  test('maps a missing ID token to a failure', () async {
    when(() => account.authentication)
        .thenReturn(const GoogleSignInAuthentication(idToken: null));

    await expectLater(
      gateway().authenticate(),
      throwsA(
        isA<AuthFailure>().having(
          (f) => f.code,
          'code',
          'google-missing-id-token',
        ),
      ),
    );
  });

  test('maps cancellation to AuthFailure.cancelled', () async {
    when(() => googleSignIn.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );

    await expectLater(
      gateway().authenticate(),
      throwsA(isA<AuthFailure>().having((f) => f.isCancelled, 'c', isTrue)),
    );
  });

  test('mapGoogleSignInException', () {
    AuthFailure map(GoogleSignInExceptionCode code) =>
        mapGoogleSignInException(GoogleSignInException(code: code));

    expect(map(GoogleSignInExceptionCode.canceled).isCancelled, isTrue);
    for (final code in [
      GoogleSignInExceptionCode.interrupted,
      GoogleSignInExceptionCode.uiUnavailable,
    ]) {
      expect(map(code).isCancelled, isFalse, reason: '$code');
      expect(map(code).code, 'google-sign-in-failed', reason: '$code');
    }
    expect(
      map(GoogleSignInExceptionCode.clientConfigurationError).code,
      'google-configuration-error',
    );
    expect(
      map(GoogleSignInExceptionCode.unknownError).code,
      'google-sign-in-failed',
    );
  });
}
