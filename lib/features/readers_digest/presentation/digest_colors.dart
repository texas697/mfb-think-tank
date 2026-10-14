import 'package:material_ui/material_ui.dart';

/// Named color tokens for the digest feature.
@immutable
class DigestColors extends ThemeExtension<DigestColors> {
  const DigestColors();

  final Color background = const Color(0xFF05070B);
  final Color card = const Color(0xFF0A0D14);
  final Color raised = const Color(0xFF111520);
  final Color border = const Color(0xFF1A1E29);
  final Color accent = const Color(0xFFDCE2EC);
  final Color onAccent = const Color(0xFF0A0F1F);
  final Color thinkTank = const Color(0xFFB9BEC4);
  final Color news = const Color(0xFFDCE2EC);
  final Color text = const Color(0xFFE9ECF2);
  final Color muted = const Color(0xFF8A94A8);
  final Color danger = const Color(0xFFFFB4AB);

  /// Colors for the nearest [Theme] (see `DigestTheme`).
  static DigestColors of(BuildContext context) =>
      Theme.of(context).extension<DigestColors>() ?? const DigestColors();

  @override
  DigestColors copyWith() => this;

  @override
  DigestColors lerp(ThemeExtension<DigestColors>? other, double t) => this;
}
