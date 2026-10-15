import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/live_media/data/media_channel.dart';
import 'package:mfb_think_tank/features/live_media/presentation/youtube_fallback.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/open_external_link.dart';

/// Persistent volume, channel stepping and broadcaster alternatives.
class MediaControls extends ConsumerWidget {
  const MediaControls({
    required this.channel,
    required this.volume,
    required this.isMuted,
    required this.isGrid,
    required this.onVolume,
    required this.onMute,
    required this.onPrevious,
    required this.onNext,
    required this.onGrid,
    super.key,
  });
  final MediaChannel channel;
  final double volume;
  final bool isMuted;
  final bool isGrid;
  final ValueChanged<double> onVolume;
  final VoidCallback onMute;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onGrid;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    children: [
      Row(
        children: [
          IconButton(
            key: const Key('media-mute'),
            tooltip: isMuted ? 'Unmute' : 'Mute',
            onPressed: onMute,
            icon: Icon(
              isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
            ),
          ),
          Expanded(
            child: Slider(
              key: const Key('media-volume'),
              value: isMuted ? 0 : volume,
              label: '${(volume * 100).round()}%',
              onChanged: onVolume,
            ),
          ),
          IconButton(
            key: const Key('media-previous'),
            tooltip: 'Previous channel',
            onPressed: onPrevious,
            icon: const Icon(Icons.skip_previous_outlined),
          ),
          IconButton(
            key: const Key('media-next'),
            tooltip: 'Next channel',
            onPressed: onNext,
            icon: const Icon(Icons.skip_next_outlined),
          ),
        ],
      ),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          TextButton.icon(
            key: const Key('media-grid'),
            onPressed: onGrid,
            icon: Icon(
              isGrid ? Icons.grid_off_outlined : Icons.grid_view_outlined,
            ),
            label: Text(isGrid ? 'Hide monitor' : 'Monitor grid'),
          ),
          TextButton.icon(
            key: const Key('media-source'),
            onPressed: () => openExternalLink(context, ref, channel.page),
            icon: const Icon(Icons.open_in_new),
            label: const Text('Broadcaster'),
          ),
          if (channel.youtube case final youtube?)
            TextButton.icon(
              key: const Key('media-youtube'),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('YouTube alternative'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      YoutubeFallback(url: youtube, title: channel.name),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}
