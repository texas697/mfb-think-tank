import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/features/readers_digest/application/article_detail_provider.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_failure.dart';
import 'package:mfb_think_tank/features/readers_digest/data/research_result.dart';

/// App lifecycle (resumed/paused) for pausing research polls.
final appLifecycleProvider =
    NotifierProvider<AppLifecycleNotifier, AppLifecycleState>(
      AppLifecycleNotifier.new,
    );

class AppLifecycleNotifier extends Notifier<AppLifecycleState> {
  @override
  AppLifecycleState build() {
    final observer = _LifecycleObserver((next) => state = next);
    final binding = WidgetsBinding.instance..addObserver(observer);
    ref.onDispose(() => binding.removeObserver(observer));
    return AppLifecycleState.resumed;
  }
}

class _LifecycleObserver with WidgetsBindingObserver {
  _LifecycleObserver(this.onChange);

  final ValueChanged<AppLifecycleState> onChange;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => onChange(state);
}

/// Research run state for one article.
@immutable
class ResearchControllerState {
  const ResearchControllerState({
    this.result = const ResearchResult(),
    this.isStarting = false,
    this.error,
  });

  final ResearchResult result;
  final bool isStarting;
  final String? error;

  ResearchControllerState copyWith({
    ResearchResult? result,
    bool? isStarting,
    String? error,
  }) => ResearchControllerState(
    result: result ?? this.result,
    isStarting: isStarting ?? this.isStarting,
    error: error,
  );
}

/// Starts and polls research for one article while the reader is open.
///
/// Polls about every 2.5 s while running, backs off on transient failures,
/// and stops on terminal state, dispose, sign-out, or pause.
final researchProvider =
    NotifierProvider.family<ResearchNotifier, ResearchControllerState, String>(
      ResearchNotifier.new,
    );

class ResearchNotifier extends Notifier<ResearchControllerState> {
  ResearchNotifier(this.id);

  static const basePollInterval = Duration(milliseconds: 2500);
  static const maxPollInterval = Duration(seconds: 20);

  final String id;
  Timer? _poll;
  Duration _interval = basePollInterval;
  int _failures = 0;

  @override
  ResearchControllerState build() {
    final uid = ref.watch(currentUidProvider);
    final lifecycle = ref.watch(appLifecycleProvider);
    ref.onDispose(() => _poll?.cancel());
    if (uid == null) return const ResearchControllerState();
    // Refresh authoritative state whenever the reader reopens or the app
    // resumes; no new generation is started.
    if (lifecycle == AppLifecycleState.resumed) {
      unawaited(_syncFromServer());
    }
    return const ResearchControllerState();
  }

  /// Starts research (or regenerates after a finished/failed run).
  Future<void> start() async {
    if (state.isStarting) return;
    state = state.copyWith(isStarting: true);
    try {
      await ref.read(digestRepositoryProvider).startResearch(id);
      _failures = 0;
      _interval = basePollInterval;
      state = state.copyWith(
        isStarting: false,
        result: const ResearchResult(
          state: 'running',
          stage: 'searching',
          progress: 0,
        ),
      );
      _schedulePoll();
    } catch (error) {
      state = state.copyWith(isStarting: false, error: _message(error));
    }
  }

  void _schedulePoll() {
    _poll?.cancel();
    _poll = Timer(_interval, _pollOnce);
  }

  Future<void> _pollOnce() async {
    if (!ref.mounted) return;
    if (ref.read(appLifecycleProvider) != AppLifecycleState.resumed) return;
    try {
      final result = await ref.read(digestRepositoryProvider).fetchResearch(id);
      _failures = 0;
      _interval = basePollInterval;
      state = state.copyWith(result: result);
      ref.read(articleDetailProvider(id).notifier).applyResearch(result);
      if (result.isRunning) _schedulePoll();
    } catch (_) {
      _failures++;
      _interval = _interval * 2 > maxPollInterval
          ? maxPollInterval
          : _interval * 2;
      if (_failures < 5) _schedulePoll();
    }
  }

  Future<void> _syncFromServer() async {
    try {
      final result = await ref.read(digestRepositoryProvider).fetchResearch(id);
      if (!ref.mounted) return;
      state = state.copyWith(result: result);
      ref.read(articleDetailProvider(id).notifier).applyResearch(result);
      if (result.isRunning) _schedulePoll();
    } catch (_) {
      // Transient; polling or the next reopen recovers.
    }
  }

  String _message(Object error) => error is DigestFailure
      ? error.message
      : 'Could not start research. Try again.';
}
