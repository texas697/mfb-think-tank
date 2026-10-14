import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/auth/presentation/widgets/brand_logo.dart';

/// Shown while the previous session is restored. Matches the native launch
/// screen so the hand-off from the OS splash is seamless.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BrandLogo(),
            SizedBox(height: 40),
            SizedBox(width: 120, child: LinearProgressIndicator(minHeight: 2)),
          ],
        ),
      ),
    );
  }
}
