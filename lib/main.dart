import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/app/app.dart';
import 'package:mfb_think_tank/app/global_error_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // One container for the whole app so the error handler shares providers
  // (API client, router) with the widget tree.
  //
  // Riverpod's default retry re-runs every failing provider ten times within
  // about thirteen seconds. Against a struggling backend that is a request
  // storm from every open app, so features back off on their own instead
  // (see digestFeedRetryProvider).
  final container = ProviderContainer(retry: (_, _) => null);
  installGlobalErrorHandler(container);
  runApp(UncontrolledProviderScope(container: container, child: const App()));
}
