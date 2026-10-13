import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mfb_think_tank/app/router.dart';
import 'package:mfb_think_tank/features/feedback/application/feedback_providers.dart';

/// Forwards uncaught Flutter and Dart errors to the feedback endpoint while
/// keeping the default console output. Call once before `runApp`.
void installGlobalErrorHandler(ProviderContainer container) {
  final reporter = container.read(errorReporterProvider);

  String? page() {
    try {
      return container.read(routerProvider).state.uri.toString();
    } catch (_) {
      return null;
    }
  }

  final presentFlutterError = FlutterError.onError;
  FlutterError.onError = (details) {
    (presentFlutterError ?? FlutterError.presentError)(details);
    unawaited(
      reporter.report(
        details.exception,
        details.stack,
        context: details.library ?? 'flutter',
        page: page(),
      ),
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(reporter.report(error, stack, page: page()));
    // Not handled: the error still reaches the default uncaught-error path.
    return false;
  };
}
