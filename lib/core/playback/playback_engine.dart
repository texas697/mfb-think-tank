import 'package:flutter/foundation.dart';

/// Small player seam for platform-independent lifecycle and failure tests.
abstract class PlaybackEngine extends ChangeNotifier {
  Object? get viewHandle;
  String? get error;
  bool get isReady;
  bool get isInPip;
  Future<void> initialize({bool forceRefresh = false});
  Future<void> setVolume(double volume);
  void toggleFullscreen();
}
