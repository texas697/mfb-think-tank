import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mfb_think_tank/app/app_routes.dart';
import 'package:mfb_think_tank/app/app_shell.dart';
import 'package:mfb_think_tank/features/dashboard/presentation/dashboard_screen.dart';
import 'package:mfb_think_tank/features/live_media/presentation/live_media_screen.dart';
import 'package:mfb_think_tank/features/profile/presentation/profile_screen.dart';
import 'package:mfb_think_tank/features/readers_digest/data/digest_query.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/article_screen.dart';
import 'package:mfb_think_tank/features/readers_digest/presentation/digest_screen.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_chat_screen.dart';
import 'package:mfb_think_tank/features/telegram/presentation/telegram_screen.dart';

/// Authenticated destinations and their retained branch navigators.
StatefulShellRoute buildShellRoute(GlobalKey<NavigatorState> root) =>
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(shell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (context, state) =>
                  DashboardScreen(query: state.uri.query),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => DigestScreen(
                query: DigestQuery.sanitized(
                  filter: state.uri.queryParameters['filter'] ?? '',
                  topic: state.uri.queryParameters['topic'] ?? '',
                  q: state.uri.queryParameters['q'] ?? '',
                ),
              ),
              routes: [
                GoRoute(
                  path: AppRoutes.article.substring(1),
                  parentNavigatorKey: root,
                  builder: (context, state) =>
                      ArticleScreen(id: state.pathParameters['id'] ?? ''),
                ),
                GoRoute(
                  path: AppRoutes.profile.substring(1),
                  parentNavigatorKey: root,
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.media,
              redirect: (context, state) => Uri(
                path: AppRoutes.mediaLocation('aljazeera'),
                query: state.uri.hasQuery ? state.uri.query : null,
              ).toString(),
            ),
            GoRoute(
              path: '${AppRoutes.media}/:channel',
              builder: (context, state) => LiveMediaScreen(
                channelId: state.pathParameters['channel'],
                isGrid: state.uri.queryParameters['grid'] == '1',
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.telegram,
              builder: (context, state) => const TelegramScreen(),
              routes: [
                GoRoute(
                  path: ':chat',
                  builder: (context, state) => TelegramChatScreen(
                    chatId: state.pathParameters['chat'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
