import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/auth/application/auth_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Which build is running, as sent with feedback and error reports.
@immutable
class AppInfo {
  const AppInfo({required this.platform, required this.version});

  /// `android`, `ios`, ... (lower-case [TargetPlatform] name).
  final String platform;

  /// `version+buildNumber`, or `unknown` when the platform cannot say.
  final String version;
}

/// The running build's [AppInfo]. Override in tests.
final appInfoProvider = FutureProvider<AppInfo>((ref) async {
  final platform = ref.watch(targetPlatformProvider).name.toLowerCase();
  try {
    final info = await PackageInfo.fromPlatform();
    return AppInfo(
      platform: platform,
      version: '${info.version}+${info.buildNumber}',
    );
  } catch (_) {
    return AppInfo(platform: platform, version: 'unknown');
  }
});
