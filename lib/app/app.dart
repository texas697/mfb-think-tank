import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';

/// Display name. Set when the app was created from flutter-firebase-template
/// (scripts/new_app.sh).
const appTitle = 'MFB Think Tank';

/// Root widget. Expects to run inside a [ProviderScope] with Firebase
/// already initialized.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(currentUidProvider, (previous, next) {
      if (previous != next) {
        PaintingBinding.instance.imageCache
          ..clear()
          ..clearLiveImages();
      }
    });
    return MaterialApp.router(
      title: appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
