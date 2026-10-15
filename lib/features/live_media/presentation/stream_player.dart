import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/core/playback/playback_engine.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';
import 'package:mfb_think_tank/features/live_media/application/playback_provider.dart';
import 'package:mfb_think_tank/features/live_media/presentation/player_surface.dart';
import 'package:mfb_think_tank/features/readers_digest/application/app_lifecycle_provider.dart';

/// Mounted native player; hidden destinations release their decoder and network.
class StreamPlayer extends ConsumerStatefulWidget {
  const StreamPlayer({
    required this.request,
    this.isActive = true,
    this.onEngineChanged,
    super.key,
  });
  final PlaybackRequest request;
  final bool isActive;
  final ValueChanged<PlaybackEngine?>? onEngineChanged;
  @override
  ConsumerState<StreamPlayer> createState() => _StreamPlayerState();
}

class _StreamPlayerState extends ConsumerState<StreamPlayer> {
  PlaybackEngine? _engine;
  Timer? _background;
  final _playerKey = GlobalKey();
  bool _hasRetriedAuth = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StreamPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.uri != widget.request.uri) {
      _release();
      _hasRetriedAuth = false;
    }
    _sync();
    if (oldWidget.request.volume != widget.request.volume) {
      unawaited(
        _engine?.setVolume(widget.request.volume).catchError((Object _) {}) ??
            Future.value(),
      );
    }
  }

  void _sync() {
    final resumed = ref.read(appLifecycleProvider) == AppLifecycleState.resumed;
    final shouldPlay = widget.isActive && (resumed || _engine?.isInPip == true);
    if (!shouldPlay) {
      _release();
      return;
    }
    if (_engine != null) return;
    final engine = ref.read(playbackFactoryProvider)(widget.request);
    _engine = engine;
    widget.onEngineChanged?.call(engine);
    engine.addListener(_changed);
    unawaited(engine.initialize(forceRefresh: _hasRetriedAuth));
  }

  void _changed() {
    if (!mounted) return;
    if (_engine?.error != null &&
        widget.request.headers != null &&
        !_hasRetriedAuth) {
      _hasRetriedAuth = true;
      final failing = _engine;
      scheduleMicrotask(() {
        if (!mounted || _engine != failing) return;
        setState(() {
          _release();
          _sync();
        });
      });
    }
    if (ref.read(appLifecycleProvider) != AppLifecycleState.resumed &&
        _engine?.isInPip != true) {
      scheduleMicrotask(() {
        if (mounted) setState(_sync);
      });
    }
    setState(() {});
  }

  void _release() {
    final engine = _engine;
    _engine = null;
    engine?.removeListener(_changed);
    engine?.dispose();
  }

  @override
  void dispose() {
    _background?.cancel();
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(appLifecycleProvider, (_, next) {
      _background?.cancel();
      if (next == AppLifecycleState.resumed) {
        _sync();
        if (mounted) setState(() {});
      } else {
        _background = Timer(const Duration(milliseconds: 250), () {
          if (mounted) setState(_sync);
        });
      }
    });
    return PlayerSurface(
      engine: _engine,
      request: widget.request,
      isActive: widget.isActive,
      playerKey: _playerKey,
      onRetry: () => setState(() {
        _release();
        _sync();
      }),
    );
  }
}
