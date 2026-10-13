import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/app/app.dart';
import 'package:mfb_think_tank/app/firebase_setup_app.dart';
import 'package:mfb_think_tank/app/global_error_handler.dart';
import 'package:mfb_think_tank/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError catch (e) {
    // Thrown by the placeholder firebase_options.dart, or by a generated one
    // when the current platform was not configured.
    runApp(FirebaseSetupApp(details: e.message ?? e.toString()));
    return;
  }

  // One container for the whole app so the error handler shares providers
  // (API client, router) with the widget tree.
  final container = ProviderContainer();
  installGlobalErrorHandler(container);
  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
