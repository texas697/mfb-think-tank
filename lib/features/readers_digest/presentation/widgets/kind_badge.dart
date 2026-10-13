import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// Think-tank (purple) or news (blue) label.
class KindBadge extends StatelessWidget {
  const KindBadge({required this.isThinkTank, super.key});

  final bool isThinkTank;

  @override
  Widget build(BuildContext context) {
    final colors = DigestColors.of(context);
    final color = isThinkTank ? colors.thinkTank : colors.news;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          isThinkTank ? 'THINK TANK' : 'NEWS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontFamily: 'GeistMono',
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}
