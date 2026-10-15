import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app_routes.dart';
import 'package:mfb_think_tank/app/destination_scope.dart';
import 'package:mfb_think_tank/app/feature_heading.dart';
import 'package:mfb_think_tank/core/playback/playback_engine.dart';
import 'package:mfb_think_tank/features/live_media/data/media_channels.dart';
import 'package:mfb_think_tank/features/live_media/presentation/media_layout.dart';
import 'package:mfb_think_tank/features/live_media/presentation/media_stage.dart';

/// Native broadcaster player with a muted multi-channel monitor.
class LiveMediaScreen extends ConsumerStatefulWidget {
  const LiveMediaScreen({this.channelId, this.isGrid = false, super.key});
  final String? channelId;
  final bool isGrid;
  @override
  ConsumerState<LiveMediaScreen> createState() => _LiveMediaScreenState();
}

class _LiveMediaScreenState extends ConsumerState<LiveMediaScreen> {
  PlaybackEngine? _player;
  double _volume = .6;
  bool _isMuted = false;

  void _go(String id, {bool? isGrid}) => context.go(
    Uri(
      path: AppRoutes.mediaLocation(id),
      queryParameters: (isGrid ?? widget.isGrid) ? {'grid': '1'} : null,
    ).toString(),
  );

  void _step(int delta) {
    final index = mediaChannels.indexOf(mediaChannelFor(widget.channelId));
    _go(mediaChannels[(index + delta) % mediaChannels.length].id);
  }

  @override
  Widget build(BuildContext context) {
    final channel = mediaChannelFor(widget.channelId);
    final isActive =
        DestinationScope.isActive(context, 2) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _step(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _step(1),
        const SingleActivator(LogicalKeyboardKey.keyF): () =>
            _player?.toggleFullscreen(),
        const SingleActivator(LogicalKeyboardKey.keyM): () =>
            setState(() => _isMuted = !_isMuted),
      },
      child: Focus(
        autofocus: isActive,
        canRequestFocus: isActive,
        child: MediaLayout(
          children: [
            const FeatureHeading(
              title: 'Live Media',
              subtitle: 'Six perspectives. One live picture.',
            ),
            MediaStage(
              channel: channel,
              isActive: isActive,
              isGrid: widget.isGrid,
              volume: _volume,
              isMuted: _isMuted,
              onChannel: _go,
              onStep: _step,
              onPlayerChanged: (player) => _player = player,
              onVolume: (value) => setState(() {
                _volume = value;
                _isMuted = value == 0;
              }),
              onMute: () => setState(() => _isMuted = !_isMuted),
              onGrid: () => _go(channel.id, isGrid: !widget.isGrid),
            ),
          ],
        ),
      ),
    );
  }
}
