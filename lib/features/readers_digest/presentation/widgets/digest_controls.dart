import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_controls_header.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_filter_bar.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/widgets/digest_search_field.dart';

/// Pinned sliver holding the search field and the filter chip row.
class DigestControls extends StatelessWidget {
  const DigestControls({
    required this.searchController,
    required this.onSearchChanged,
    required this.selectedFilter,
    required this.onFilterSelected,
    super.key,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: DigestControlsHeader(
        height: 120 * DigestControlsHeader.scaleOf(context),
        child: Column(
          children: [
            DigestSearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
            DigestFilterBar(
              selected: selectedFilter,
              onSelected: onFilterSelected,
            ),
          ],
        ),
      ),
    );
  }
}
