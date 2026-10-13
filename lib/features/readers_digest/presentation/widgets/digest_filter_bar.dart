import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_controls_header.dart';

/// The four server filters as a horizontal chip row.
class DigestFilterBar extends StatelessWidget {
  const DigestFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  static const _labels = {
    DigestQuery.filterAll: 'All',
    DigestQuery.filterForYou: 'For you',
    DigestQuery.filterThinkTank: 'Think tanks',
    DigestQuery.filterNews: 'News',
  };

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
          for (final entry in _labels.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                key: Key('filter-${entry.key}'),
                label: Text(entry.value),
                selected: selected == entry.key,
                selectedColor: colors.accent.withValues(alpha: 0.22),
                backgroundColor: colors.raised,
                side: BorderSide(color: colors.border),
                onSelected: (_) => onSelected(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}
