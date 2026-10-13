import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';

/// Current feed query, kept in sync with the `/` route's query parameters.
///
/// Filter/topic changes come from the router (pushed as history entries);
/// search text is debounced by the search field before it lands here.
final digestQueryProvider = NotifierProvider<DigestQueryNotifier, DigestQuery>(
  DigestQueryNotifier.new,
);

class DigestQueryNotifier extends Notifier<DigestQuery> {
  @override
  DigestQuery build() => const DigestQuery();

  /// Replaces the query when it differs (called from the route sync).
  void sync(DigestQuery next) {
    if (state == next) return;
    state = next;
  }
}
