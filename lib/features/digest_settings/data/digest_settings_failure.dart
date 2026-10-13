/// Settings feature failures. Never raw SDK/HTTP errors.
sealed class DigestSettingsFailure implements Exception {
  const DigestSettingsFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class SettingsUnauthenticated extends DigestSettingsFailure {
  const SettingsUnauthenticated([
    super.message = 'Your session has expired. Sign in again.',
  ]);
}

final class SettingsForbidden extends DigestSettingsFailure {
  const SettingsForbidden([
    super.message = 'This account does not have access.',
  ]);
}

/// The server has no BYOK encryption key; settings endpoints may 503.
final class SettingsUnavailable extends DigestSettingsFailure {
  const SettingsUnavailable([
    super.message =
        'AI key storage is unavailable on the server. Try again later.',
  ]);
}

/// Validation or provider rejection (400/502 from save/test).
final class SettingsRejected extends DigestSettingsFailure {
  const SettingsRejected(super.message);
}

final class SettingsTimeout extends DigestSettingsFailure {
  const SettingsTimeout([super.message = 'The request timed out. Try again.']);
}

final class SettingsNetwork extends DigestSettingsFailure {
  const SettingsNetwork([
    super.message = 'Could not reach the digest service.',
  ]);
}

final class SettingsMalformed extends DigestSettingsFailure {
  const SettingsMalformed([
    super.message = 'The server returned an unexpected response.',
  ]);
}

final class SettingsUnknown extends DigestSettingsFailure {
  const SettingsUnknown([super.message = 'Something went wrong. Try again.']);
}
