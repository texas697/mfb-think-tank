/// Browser operations used by the session state machine, independently testable.
abstract interface class DashboardBrowserPort {
  Future<void> load(Uri uri);
  Future<Uri?> currentUri();
  Future<void> execute(String script);
}
