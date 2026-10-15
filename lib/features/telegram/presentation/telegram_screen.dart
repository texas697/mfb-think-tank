import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/destination_scope.dart';
import 'package:mfb_think_tank/app/feature_heading.dart';
import 'package:mfb_think_tank/features/readers_digest/application/digest_api_providers.dart';
import 'package:mfb_think_tank/features/telegram/application/telegram_providers.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_directory.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_gate.dart';

/// Read-only Telegram channel directory with retained local search state.
class TelegramScreen extends ConsumerStatefulWidget {
  const TelegramScreen({super.key});
  @override
  ConsumerState<TelegramScreen> createState() => _TelegramScreenState();
}

class _TelegramScreenState extends ConsumerState<TelegramScreen> {
  String _query = '';
  String? _ownerUid;
  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(currentUidProvider);
    if (_ownerUid != uid) {
      _ownerUid = uid;
      _query = '';
    }
    final isActive =
        DestinationScope.isActive(context, 3) &&
        (ModalRoute.of(context)?.isCurrent ?? true);
    return KeyedSubtree(
      key: ValueKey(uid),
      child: Column(
        children: [
          FeatureHeading(
            title: 'Telegram',
            subtitle: 'Published channels. Read-only intelligence.',
            trailing: IconButton(
              key: const Key('telegram-refresh'),
              tooltip: 'Refresh Telegram',
              onPressed: () => ref.invalidate(telegramStatusProvider),
              icon: const Icon(Icons.refresh),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              key: const Key('telegram-search'),
              onChanged: (text) => setState(() => _query = text),
              decoration: const InputDecoration(
                labelText: 'Search channels',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: isActive
                ? TelegramGate(child: TelegramDirectory(query: _query))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
