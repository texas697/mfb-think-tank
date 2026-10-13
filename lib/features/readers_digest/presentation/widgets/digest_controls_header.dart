import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// Pinned sliver delegate that keeps search and filters on screen.
class DigestControlsHeader extends SliverPersistentHeaderDelegate {
  DigestControlsHeader({required this.child, required this.height});

  final Widget child;
  final double height;

  /// Text scale (at least 1) used to size pinned rows so large text fits.
  static double scaleOf(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) / 14 < 1
      ? 1
      : MediaQuery.textScalerOf(context).scale(14) / 14;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => ColoredBox(
    color: DigestColors.of(context).background,
    child: ClipRect(child: child),
  );

  @override
  bool shouldRebuild(DigestControlsHeader oldDelegate) => true;
}
