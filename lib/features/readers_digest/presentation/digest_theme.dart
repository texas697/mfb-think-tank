import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_colors.dart';

/// [AppTheme.dark] plus the [DigestColors] tokens the digest widgets read.
abstract final class DigestTheme {
  static ThemeData get data =>
      AppTheme.dark.copyWith(extensions: const [DigestColors()]);
}
