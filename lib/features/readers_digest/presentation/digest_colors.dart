import 'package:material_ui/material_ui.dart';

/// Named color tokens for the Reader's Digest feature.
@immutable
class DigestColors extends ThemeExtension<DigestColors> {
  const DigestColors();

  final Color background = const Color(0xFF05070B);
  final Color card = const Color(0xFF0A0D14);
  final Color raised = const Color(0xFF111520);
  final Color border = const Color(0xFF1E2433);
  final Color accent = const Color(0xFF4F8CFF);
  final Color thinkTank = const Color(0xFFA78BFA);
  final Color news = const Color(0xFF4F8CFF);
  final Color text = const Color(0xFFE8EBF2);
  final Color muted = const Color(0xFF9AA3B8);
  final Color danger = const Color(0xFFF87171);

  /// Colors for the nearest [Theme] (see `DigestTheme`).
  static DigestColors of(BuildContext context) =>
      Theme.of(context).extension<DigestColors>() ?? const DigestColors();

  @override
  DigestColors copyWith() => this;

  @override
  DigestColors lerp(ThemeExtension<DigestColors>? other, double t) => this;
}
