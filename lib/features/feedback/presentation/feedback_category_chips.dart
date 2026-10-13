import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/feedback/data/feedback_report.dart';

/// One chip per user-selectable [FeedbackCategory].
class FeedbackCategoryChips extends StatelessWidget {
  const FeedbackCategoryChips({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final FeedbackCategory selected;

  /// Null disables the chips.
  final ValueChanged<FeedbackCategory>? onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final c in FeedbackCategory.userChoices)
          ChoiceChip(
            key: Key('feedback-category-${c.id}'),
            label: Text(c.label),
            selected: c == selected,
            onSelected: onSelected == null ? null : (_) => onSelected!(c),
          ),
      ],
    );
  }
}
