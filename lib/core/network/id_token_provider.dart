/// Supplies bearer tokens for authenticated API calls.
///
/// The credential source stays behind this seam so feature code never names
/// an authentication SDK.
abstract interface class IdTokenProvider {
  /// Returns a valid token, refreshing it first when [forceRefresh].
  ///
  /// Throws [StateError] when nobody is signed in.
  Future<String> getIdToken({bool forceRefresh = false});
}
