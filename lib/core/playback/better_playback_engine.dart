import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:mfb_think_tank/core/playback/playback_engine.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';

/// Native HLS/AV playback, fullscreen and capability-gated PiP.
class BetterPlaybackEngine extends PlaybackEngine {
  BetterPlaybackEngine(this.request) {
    controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoDispose: false,
        handleLifecycle: false,
        aspectRatio: 16 / 9,
        useRootNavigator: true,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          showControls: !request.isPreview,
          enablePip: !request.isPreview && !request.isAudio,
          enableProgressBar: !request.isLive,
          enableProgressText: !request.isLive,
          enableSkips: !request.isLive,
          enableSubtitles: false,
          enableQualities: false,
          enablePlaybackSpeed: !request.isLive,
          enableMute: request.headers != null,
          enableOverflowMenu: false,
        ),
      ),
    );
    controller.addEventsListener(_event);
  }
  final PlaybackRequest request;
  late final BetterPlayerController controller;
  bool _isDisposed = false;
  double? _volume;
  bool _isReady = false;
  bool _isInPip = false;
  String? _error;
  Timer? _deadline;
  @override
  Object get viewHandle => controller;
  @override
  bool get isReady => _isReady;
  @override
  bool get isInPip =>
      _isInPip || controller.videoPlayerController?.value.isPip == true;
  @override
  String? get error => _error;

  @override
  Future<void> initialize({bool forceRefresh = false}) async {
    _deadline = Timer(const Duration(seconds: 30), _fail);
    try {
      final headers = await request.headers?.call(forceRefresh);
      if (_isDisposed || _error != null) return;
      await controller.setupDataSource(
        BetterPlayerDataSource(
          BetterPlayerDataSourceType.network,
          request.uri.toString(),
          liveStream: request.isLive,
          headers: headers,
          useAsmsSubtitles: false,
          useAsmsTracks: false,
          useAsmsAudioTracks: false,
          // Private attachment paths have no extension for native inference.
          videoFormat: request.isLive
              ? BetterPlayerVideoFormat.hls
              : BetterPlayerVideoFormat.other,
        ),
      );
      if (_isDisposed || _error != null) return;
      await controller.setVolume(_volume ?? request.volume);
      if (!_isDisposed && request.isAutoPlay) await controller.play();
    } catch (_) {
      _fail();
    }
  }

  void _event(BetterPlayerEvent event) {
    if (_isDisposed) return;
    if (event.betterPlayerEventType == BetterPlayerEventType.initialized) {
      _deadline?.cancel();
      _isReady = true;
    } else if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      _fail();
      return;
    } else if (event.betterPlayerEventType == BetterPlayerEventType.pipStart) {
      _isInPip = true;
    } else if (event.betterPlayerEventType == BetterPlayerEventType.pipStop) {
      _isInPip = false;
    } else {
      return;
    }
    notifyListeners();
  }

  void _fail() {
    if (_isDisposed) return;
    if (_error != null) return;
    _deadline?.cancel();
    controller.removeEventsListener(_event);
    controller.dispose(forceDispose: true);
    _error = 'This stream could not be played. It may be offline or unavailable in your region.';
    notifyListeners();
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0, 1);
    if (!_isDisposed && _isReady && _error == null) {
      await controller.setVolume(volume.clamp(0, 1));
    }
  }

  @override
  void toggleFullscreen() {
    if (!_isDisposed && _isReady && _error == null) {
      controller.toggleFullScreen();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _deadline?.cancel();
    controller.removeEventsListener(_event);
    controller.dispose(forceDispose: true);
    super.dispose();
  }
}
