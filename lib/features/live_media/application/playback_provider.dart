import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/core/playback/better_playback_engine.dart';
import 'package:mfb_think_tank/core/playback/playback_engine.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';

/// Platform playback seam, replaced by fake engines in widget tests.
final playbackFactoryProvider =
    Provider<PlaybackEngine Function(PlaybackRequest)>(
      (ref) => BetterPlaybackEngine.new,
    );
