import 'package:flutter/widgets.dart';

/// Selected destination, independent of retained branch widget lifetimes.
class DestinationScope extends InheritedWidget {
  const DestinationScope({
    required this.index,
    required super.child,
    super.key,
  });

  final int index;

  static bool isActive(BuildContext context, int index) =>
      context.dependOnInheritedWidgetOfExactType<DestinationScope>()?.index ==
          index ||
      context.getInheritedWidgetOfExactType<DestinationScope>() == null;

  @override
  bool updateShouldNotify(DestinationScope oldWidget) =>
      index != oldWidget.index;
}
