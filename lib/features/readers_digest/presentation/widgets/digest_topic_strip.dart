import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/data/topic_count.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/topic_label.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_controls_header.dart';

/// Horizontal topic chips with library counts. Tapping the selected topic
/// clears it. The original tag is sent to the server, never the label.
class DigestTopicStrip extends StatelessWidget {
  const DigestTopicStrip({
    required this.topics,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<TopicCount> topics;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = DigestColors.of(context);
    return SizedBox(
      height: 48 * DigestControlsHeader.scaleOf(context),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final topic in topics)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                key: Key('topic-${topic.topic}'),
                label: Text('${topicLabel(topic.topic)} ${topic.count}'),
                selected: selected == topic.topic,
                selectedColor: colors.accent.withValues(alpha: 0.22),
                backgroundColor: colors.card,
                side: BorderSide(color: colors.border),
                onSelected: (on) => onSelected(on ? topic.topic : ''),
              ),
            ),
        ],
      ),
    );
  }
}
