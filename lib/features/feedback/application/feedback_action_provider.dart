import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/feedback/application/feedback_providers.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_failure.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';

/// Status of the feedback sheet's send action.
@immutable
class FeedbackActionState {
  const FeedbackActionState({this.isBusy = false, this.notice});

  final bool isBusy;

  /// Error message to surface once; null after a success.
  final String? notice;
}

/// Sends one report at a time from the feedback sheet.
final feedbackActionProvider =
    NotifierProvider<FeedbackActionNotifier, FeedbackActionState>(
      FeedbackActionNotifier.new,
    );

class FeedbackActionNotifier extends Notifier<FeedbackActionState> {
  @override
  FeedbackActionState build() => const FeedbackActionState();

  /// True when the report was accepted; otherwise [FeedbackActionState.notice]
  /// explains why not.
  Future<bool> send(FeedbackReport report) async {
    if (state.isBusy) return false;
    state = const FeedbackActionState(isBusy: true);
    try {
      await ref.read(feedbackRepositoryProvider).submit(report);
      state = const FeedbackActionState();
      return true;
    } on FeedbackFailure catch (e) {
      state = FeedbackActionState(notice: e.message);
      return false;
    } catch (_) {
      state = FeedbackActionState(notice: const FeedbackUnknown().message);
      return false;
    }
  }

  void clearNotice() {
    if (state.notice != null) state = const FeedbackActionState();
  }
}
