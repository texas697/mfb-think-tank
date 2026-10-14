import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/presentation/widgets/brand_logo.dart';

/// Centered, width-constrained, scrollable layout shared by auth screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.children,
    this.title,
    this.subtitle,
    this.showAppBar = false,
    this.showLogo = false,
    super.key,
  });

  /// Heading under the logo. Omit when the logo alone is the heading.
  final String? title;
  final String? subtitle;
  final List<Widget> children;

  /// Shows a back button (for screens pushed on top of sign-in).
  final bool showAppBar;

  /// Shows the brand logo above [title] (the sign-in landing screen).
  final bool showLogo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: showAppBar ? AppBar() : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo) ...[
                    const Center(child: BrandLogo()),
                    const SizedBox(height: 24),
                  ],
                  if (title != null)
                    Text(
                      title!,
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
