import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/data/auth_failure.dart';

/// Shows [message] in a [SnackBar], replacing any visible one.
void showSnackMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Adds a busy flag and uniform error handling to auth screens.
mixin AuthActionMixin<T extends StatefulWidget> on State<T> {
  bool _busy = false;

  /// True while an action started by [runAuthAction] is in flight.
  bool get busy => _busy;

  /// Runs [action], showing [AuthFailure]s in a snackbar. Cancellations are
  /// silent. Returns true on success. Ignores calls while [busy].
  Future<bool> runAuthAction(Future<void> Function() action) async {
    if (_busy) return false;
    setState(() => _busy = true);
    try {
      await action();
      return true;
    } on AuthFailure catch (failure) {
      if (!failure.isCancelled && mounted) {
        showSnackMessage(context, failure.message);
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
