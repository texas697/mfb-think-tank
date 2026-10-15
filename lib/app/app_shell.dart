import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app_toolbar.dart';
import 'package:mfb_think_tank/app/destination_scope.dart';
import 'package:mfb_think_tank/app/theme.dart';

/// Retains each destination’s navigation while keeping chrome native.
class AppShell extends StatelessWidget {
  const AppShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  static const _labels = ['Dashboard', 'Digest', 'Live Media', 'Telegram'];
  static const _icons = [
    Icons.public_outlined,
    Icons.auto_stories_outlined,
    Icons.live_tv_outlined,
    Icons.forum_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 840;
    return DestinationScope(
      index: shell.currentIndex,
      child: Scaffold(
        body: SafeArea(
          bottom: isWide,
          child: Column(
            children: [
              const AppToolbar(),
              Expanded(
                child: Row(
                  children: [
                    if (isWide)
                      NavigationRail(
                        selectedIndex: shell.currentIndex,
                        onDestinationSelected: shell.goBranch,
                        labelType: NavigationRailLabelType.all,
                        destinations: [
                          for (var i = 0; i < _labels.length; i++)
                            NavigationRailDestination(
                              icon: Icon(_icons[i], key: Key('nav-$i')),
                              label: Text(_labels[i]),
                            ),
                        ],
                      ),
                    Expanded(child: shell),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
                backgroundColor: AppTheme.surface,
                selectedIndex: shell.currentIndex,
                onDestinationSelected: shell.goBranch,
                destinations: [
                  for (var i = 0; i < _labels.length; i++)
                    NavigationDestination(
                      key: Key('nav-$i'),
                      icon: Icon(_icons[i]),
                      label: _labels[i],
                    ),
                ],
              ),
      ),
    );
  }
}
