import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debounces search text so typing does not fire a request per keystroke.
///
/// Owned by the search field widget; cancel on dispose.
class SearchDebounce {
  SearchDebounce({required this.onDebounce, this.delay = defaultDelay});

  static const defaultDelay = Duration(milliseconds: 250);

  final Duration delay;
  final ValueChanged<String> onDebounce;
  Timer? _timer;

  /// Schedules a debounced call with the latest [text].
  void schedule(String text) {
    _timer?.cancel();
    _timer = Timer(delay, () => onDebounce(text));
  }

  /// Cancels any pending call.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Cancels and drops the timer (call from dispose).
  void dispose() => cancel();
}
