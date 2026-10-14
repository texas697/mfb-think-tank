import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// Dark feature theme shared by the digest screens and the account sheet.
abstract final class DigestTheme {
  static const _colors = DigestColors();

  static ThemeData get data {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: _colors.accent,
          brightness: Brightness.dark,
          surface: _colors.card,
        ).copyWith(
          primary: _colors.accent,
          onPrimary: _colors.onAccent,
          error: _colors.danger,
        );
    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: _colors.background,
      fontFamily: 'Geist',
      extensions: const [DigestColors()],
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: _colors.background,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: _colors.border,
      textTheme: base.textTheme.apply(
        bodyColor: _colors.text,
        displayColor: _colors.text,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _colors.raised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _colors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }
}
