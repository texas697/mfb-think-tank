import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens an external link; resolves to false when it could not be launched.
typedef LaunchLink = Future<bool> Function(Uri uri);

/// Launches original/source links in the system browser. Override in tests.
final externalLinkProvider = Provider<LaunchLink>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);

/// Parses [url] and returns it only when it is a valid http(s) link.
Uri? parseHttpUrl(String? url) {
  final uri = url == null ? null : Uri.tryParse(url.trim());
  if (uri == null || !uri.hasAuthority) return null;
  return uri.scheme == 'http' || uri.scheme == 'https' ? uri : null;
}
