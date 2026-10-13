import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mfb_think_tank/features/readers_digest/application/external_link_provider.dart';

/// Opens [url] when it is a valid http(s) link; otherwise tells the user.
Future<void> openExternalLink(
  BuildContext context,
  WidgetRef ref,
  String? url,
) async {
  final uri = parseHttpUrl(url);
  final messenger = ScaffoldMessenger.of(context);
  final launched = uri != null && await ref.read(externalLinkProvider)(uri);
  if (launched) return;
  messenger.showSnackBar(const SnackBar(content: Text('Could not open link.')));
}
