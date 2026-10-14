import 'package:material_ui/material_ui.dart';

/// App-wide Material 3 theme in the MFB Services Intelligence palette
/// (mirrors `reader.css` / `digest.html` in the Crucix dashboard).
///
/// The brand is dark only, so [App] pins `ThemeMode.dark`.
abstract final class AppTheme {
  static const background = Color(0xFF05070B);
  static const surface = Color(0xFF0A0D14);
  static const raised = Color(0xFF111520);
  static const border = Color(0xFF1A1E29);
  static const accent = Color(0xFFDCE2EC);
  static const onAccent = Color(0xFF0A0F1F);
  static const text = Color(0xFFE9ECF2);
  static const muted = Color(0xFF8A94A8);
  static const danger = Color(0xFFFFB4AB);

  static ThemeData get dark {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: surface,
        ).copyWith(
          primary: accent,
          onPrimary: onAccent,
          onSurfaceVariant: muted,
          outline: border,
          error: danger,
        );
    final base = ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Geist',
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
      ),
      dividerColor: border,
      textTheme: base.textTheme.apply(bodyColor: text, displayColor: text),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
