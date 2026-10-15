import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reloads the web profile after native account settings close.
final dashboardRevisionProvider =
    NotifierProvider<DashboardRevisionNotifier, int>(
      DashboardRevisionNotifier.new,
    );

class DashboardRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void refresh() => state++;
}
