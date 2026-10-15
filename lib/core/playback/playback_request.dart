/// Playback options without exposing a platform SDK to feature screens.
class PlaybackRequest {
  const PlaybackRequest({
    required this.uri,
    required this.title,
    this.isLive = false,
    this.isPreview = false,
    this.isAudio = false,
    this.isAutoPlay = true,
    this.volume = .6,
    this.headers,
  });
  final Uri uri;
  final String title;
  final bool isLive;
  final bool isPreview;
  final bool isAudio;
  final bool isAutoPlay;
  final double volume;
  final Future<Map<String, String>> Function(bool force)? headers;
}
