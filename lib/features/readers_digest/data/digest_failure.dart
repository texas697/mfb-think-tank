/// Feature failures thrown by the digest repository. Never raw SDK/HTTP errors.
sealed class DigestFailure implements Exception {
  const DigestFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// No valid session; the user must sign in again.
final class DigestUnauthenticated extends DigestFailure {
  const DigestUnauthenticated([
    super.message = 'Your session has expired. Sign in again.',
  ]);
}

/// The access policy rejected this account.
final class DigestForbidden extends DigestFailure {
  const DigestForbidden([super.message = 'This account does not have access.']);
}

final class DigestNotFound extends DigestFailure {
  const DigestNotFound([super.message = 'Article not found.']);
}

/// The article could not be extracted well enough to summarize.
final class DigestInsufficientText extends DigestFailure {
  const DigestInsufficientText([
    super.message = 'Could not read enough of this article to write it up. Open the original instead.',
  ]);
}

/// No AI key is configured on the server for this user.
final class DigestMissingAiSettings extends DigestFailure {
  const DigestMissingAiSettings([
    super.message = 'Add your AI API key in settings first.',
  ]);
}

/// The saved/submitted AI settings were rejected.
final class DigestInvalidAiSettings extends DigestFailure {
  const DigestInvalidAiSettings(super.message);
}

/// The backend is temporarily unavailable (e.g. 503).
final class DigestUnavailable extends DigestFailure {
  const DigestUnavailable([
    super.message = 'The digest service is temporarily unavailable.',
  ]);
}

final class DigestTimeout extends DigestFailure {
  const DigestTimeout([
    super.message = 'The request timed out. Check your connection and retry.',
  ]);
}

final class DigestNetwork extends DigestFailure {
  const DigestNetwork([
    super.message =
        'Could not reach the digest service. Check your connection.',
  ]);
}

final class DigestMalformed extends DigestFailure {
  const DigestMalformed([
    super.message = 'The server returned an unexpected response.',
  ]);
}

final class DigestTooManyRequests extends DigestFailure {
  const DigestTooManyRequests([
    super.message = 'Too many requests. Wait a moment and try again.',
  ]);
}

final class DigestUnknown extends DigestFailure {
  const DigestUnknown([super.message = 'Something went wrong. Try again.']);
}
