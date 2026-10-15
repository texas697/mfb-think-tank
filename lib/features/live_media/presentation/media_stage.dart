import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/core/playback/playback_engine.dart';
import 'package:mfb_think_tank/core/playback/playback_request.dart';
import 'package:mfb_think_tank/features/live_media/data/media_channel.dart';
import 'package:mfb_think_tank/features/live_media/data/media_channels.dart';
import 'package:mfb_think_tank/features/live_media/presentation/media_controls.dart';
import 'package:mfb_think_tank/features/live_media/presentation/media_monitor_grid.dart';
import 'package:mfb_think_tank/features/live_media/presentation/stream_player.dart';

/// Flat native channel selector, player and monitor content.
class MediaStage extends StatelessWidget {
  const MediaStage({
    required this.channel,
    required this.isActive,
    required this.isGrid,
    required this.volume,
    required this.isMuted,
    required this.onChannel,
    required this.onVolume,
    required this.onMute,
    required this.onStep,
    required this.onGrid,
    required this.onPlayerChanged,
    super.key,
  });
  final MediaChannel channel;
  final bool isActive;
  final bool isGrid;
  final double volume;
  final bool isMuted;
  final ValueChanged<String> onChannel;
  final ValueChanged<double> onVolume;
  final VoidCallback onMute;
  final ValueChanged<int> onStep;
  final VoidCallback onGrid;
  final ValueChanged<PlaybackEngine?> onPlayerChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final item in mediaChannels)
            ChoiceChip(
              key: Key('channel-${item.id}'),
              label: Text(item.name),
              selected: channel.id == item.id,
              onSelected: (_) => onChannel(item.id),
            ),
        ],
      ),
      const SizedBox(height: 16),
      Text(channel.name, style: Theme.of(context).textTheme.titleLarge),
      Text(
        '${channel.region} · Live broadcast',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
      StreamPlayer(
        key: ValueKey(channel.id),
        isActive: isActive,
        onEngineChanged: onPlayerChanged,
        request: PlaybackRequest(
          uri: Uri.parse(channel.hls),
          title: channel.name,
          isLive: true,
          volume: isMuted ? 0 : volume,
        ),
      ),
      MediaControls(
        channel: channel,
        volume: volume,
        isMuted: isMuted,
        isGrid: isGrid,
        onVolume: onVolume,
        onMute: onMute,
        onPrevious: () => onStep(-1),
        onNext: () => onStep(1),
        onGrid: onGrid,
      ),
      const SizedBox(height: 8),
      Text(
        'Streams are provided by the broadcasters. Availability can vary by region.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      if (isGrid) MediaMonitorGrid(isActive: isActive),
    ],
  );
}
