import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app.dart';
import 'package:mfb_think_tank/app/theme.dart';

/// Shown instead of [App] when Firebase could not be initialized, typically
/// because `scripts/configure_firebase.sh` has not been run yet.
class FirebaseSetupApp extends StatelessWidget {
  const FirebaseSetupApp({required this.details, super.key});

  /// Error text from the failed initialization.
  final String details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Connect Firebase',
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'This app has not been connected to a Firebase '
                          'project yet. From the project root run:',
                        ),
                        const SizedBox(height: 12),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(12),
                            child: SelectableText(
                              'scripts/configure_firebase.sh',
                              style: TextStyle(fontFamily: 'monospace'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('Then fully restart the app.'),
                        const SizedBox(height: 24),
                        ExpansionTile(
                          tilePadding: EdgeInsets.zero,
                          title: const Text('Details'),
                          children: [SelectableText(details)],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
