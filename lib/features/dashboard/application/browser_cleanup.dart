/// Serializes browser cookie/storage cleanup across rapid user/tab changes.
abstract final class BrowserCleanup {
  static Future<void> _pending = Future.value();

  static Future<void> run(Future<void> Function() operation) {
    final next = _pending.then((_) => operation());
    _pending = next.catchError((Object _) {});
    return next;
  }
}
