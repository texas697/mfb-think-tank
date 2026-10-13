/// Feedback feature failures. Never raw SDK/HTTP errors.
sealed class FeedbackFailure implements Exception {
  const FeedbackFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The server's per-user hourly limit was hit (429).
final class FeedbackRateLimited extends FeedbackFailure {
  const FeedbackRateLimited([
    super.message = 'Too much feedback in the last hour. Try again later.',
  ]);
}

/// Validation failure (400/413) with the server's message.
final class FeedbackRejected extends FeedbackFailure {
  const FeedbackRejected(super.message);
}

final class FeedbackUnauthenticated extends FeedbackFailure {
  const FeedbackUnauthenticated([
    super.message = 'Your session has expired. Sign in again.',
  ]);
}

final class FeedbackTimeout extends FeedbackFailure {
  const FeedbackTimeout([super.message = 'The request timed out. Try again.']);
}

final class FeedbackNetwork extends FeedbackFailure {
  const FeedbackNetwork([
    super.message = 'Could not reach the server. Check your connection.',
  ]);
}

final class FeedbackUnknown extends FeedbackFailure {
  const FeedbackUnknown([
    super.message = 'Could not send feedback. Try again.',
  ]);
}
