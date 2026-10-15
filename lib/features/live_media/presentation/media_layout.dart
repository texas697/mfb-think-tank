import 'package:material_ui/material_ui.dart';

/// Scrollable, readable media canvas shared by phone and tablet widths.
class MediaLayout extends StatelessWidget {
  const MediaLayout({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: ListView(
        key: const PageStorageKey('live-media-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: children,
      ),
    ),
  );
}
