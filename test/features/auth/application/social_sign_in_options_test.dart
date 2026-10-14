import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';

void main() {
  SocialSignInOptions optionsFor(TargetPlatform platform) {
    final container = ProviderContainer.test(
      overrides: [targetPlatformProvider.overrideWithValue(platform)],
    );
    return container.read(socialSignInOptionsProvider);
  }

  test('social sign-in is off on every platform in the FOSS build', () {
    for (final platform in TargetPlatform.values) {
      final options = optionsFor(platform);
      expect(options.showGoogle, isFalse, reason: '$platform');
      expect(options.googleConfigured, isFalse, reason: '$platform');
      expect(options.showApple, isFalse, reason: '$platform');
    }
  });
}
