import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/app/app_routes.dart';
import 'package:mfb_think_tank/app/theme.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_dialog.dart';
import 'package:mfb_think_tank/features/telegram/data/telegram_paths.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_image.dart';

/// Channel row with real avatar, preview, and the server’s unread count.
class TelegramDialogTile extends StatelessWidget {
  const TelegramDialogTile({required this.dialog, super.key});
  final TelegramDialog dialog;
  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.background,
    child: ListTile(
      key: Key('telegram-chat-${dialog.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: SizedBox.square(
        dimension: 44,
        child: ClipOval(
          child: dialog.hasPhoto
              ? TelegramImage(
                  path: TelegramPaths.avatar(dialog.id),
                  height: 44,
                  label: '${dialog.title} avatar',
                )
              : ColoredBox(
                  color: AppTheme.raised,
                  child: Center(
                    child: Text(
                      dialog.title.isEmpty
                          ? '?'
                          : dialog.title.characters.first.toUpperCase(),
                    ),
                  ),
                ),
        ),
      ),
      title: Text(dialog.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        dialog.lastMessage.isEmpty ? dialog.type : dialog.lastMessage,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: dialog.unreadCount > 0
          ? Badge(label: Text('${dialog.unreadCount}'))
          : const Icon(Icons.chevron_right),
      onTap: () => context.go(AppRoutes.telegramLocation(dialog.id)),
    ),
  );
}
