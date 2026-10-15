/// A broadcaster and its existing Crucix playback alternatives.
class MediaChannel {
  const MediaChannel({
    required this.id,
    required this.name,
    required this.region,
    required this.hls,
    required this.page,
    this.youtube,
  });
  final String id;
  final String name;
  final String region;
  final String hls;
  final String page;
  final String? youtube;
}
