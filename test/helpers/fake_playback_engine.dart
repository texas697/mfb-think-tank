import 'package:mfb_think_tank/core/playback/playback_engine.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';

class FakePlaybackEngine extends PlaybackEngine {
  FakePlaybackEngine(this.request);
  final PlaybackRequest request;
  bool isDisposed = false;
  double? lastVolume;
  bool? forcedRefresh;
  int fullscreenToggles = 0;
  @override
  void toggleFullscreen() {
    fullscreenToggles++;
  }

  @override
  Object? get viewHandle => null;
  @override
  String? error;
  @override
  bool isReady = true;
  @override
  bool isInPip = false;
  @override
  Future<void> initialize({bool forceRefresh = false}) async {
    forcedRefresh = forceRefresh;
  }

  @override
  Future<void> setVolume(double value) async {
    lastVolume = value;
  }

  void fail() {
    error = 'The stream failed.';
    notifyListeners();
  }

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }
}
