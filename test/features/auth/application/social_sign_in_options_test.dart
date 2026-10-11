import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/core/config/app_config.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';

void main() {
  SocialSignInOptions optionsFor(
    TargetPlatform platform, {
    AppConfig config = const AppConfig(),
  }) {
    final container = ProviderContainer.test(
      overrides: [
        targetPlatformProvider.overrideWithValue(platform),
        appConfigProvider.overrideWithValue(config),
      ],
    );
    return container.read(socialSignInOptionsProvider);
  }

  test('Android shows Google but never Apple', () {
    final options = optionsFor(
      TargetPlatform.android,
      config: const AppConfig(googleServerClientId: 'server'),
    );
    expect(options.showGoogle, isTrue);
    expect(options.googleConfigured, isTrue);
    expect(options.showApple, isFalse);
  });

  test('iOS shows Apple, and Google needs the iOS client id', () {
    final options = optionsFor(
      TargetPlatform.iOS,
      config: const AppConfig(googleServerClientId: 'server'),
    );
    expect(options.showApple, isTrue);
    expect(options.showGoogle, isTrue);
    expect(options.googleConfigured, isFalse);
  });

  test('unsupported platforms show no social buttons', () {
    final options = optionsFor(TargetPlatform.linux);
    expect(options.showGoogle, isFalse);
    expect(options.showApple, isFalse);
  });
}
