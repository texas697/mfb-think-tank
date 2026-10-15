import 'package:mfb_think_tank/features/live_media/data/media_channel.dart';

/// Broadcaster definitions matching Crucix channels.ts at 17d26fd.
const mediaChannels = [
  MediaChannel(
    id: 'aljazeera',
    name: 'Al Jazeera English',
    region: 'Qatar',
    hls: 'https://live-hls-apps-aje-fa.getaj.net/AJE/index.m3u8',
    youtube: 'https://www.youtube.com/watch?v=gCNeDWCI0vo',
    page: 'https://www.aljazeera.com/live',
  ),
  MediaChannel(
    id: 'rt',
    name: 'RT',
    region: 'Russia',
    hls: 'https://rt-glb.rttv.com/dvr/rtnews/playlist.m3u8',
    page: 'https://www.rt.com/on-air/',
  ),
  MediaChannel(
    id: 'presstv',
    name: 'Press TV',
    region: 'Iran (English)',
    hls: 'https://live.presstv.co.uk/hls/presstv.m3u8',
    page: 'https://www.presstv.ir/',
  ),
  MediaChannel(
    id: 'iranintl',
    name: 'Iran International',
    region: 'Iran (English)',
    hls: 'https://live.livetvstream.co.uk/LS-63503-4/index.m3u8',
    youtube: 'https://www.youtube.com/watch?v=5JDxjsAVaGk',
    page: 'https://www.iranintl.com/live',
  ),
  MediaChannel(
    id: 'dw',
    name: 'DW English',
    region: 'Germany',
    hls: 'https://dwamdstream103.akamaized.net/hls/live/2015526/dwstream103/master.m3u8',
    page: 'https://www.dw.com/en/live-tv/channel-english',
  ),
  MediaChannel(
    id: 'france24',
    name: 'France 24 English',
    region: 'France',
    hls: 'https://amg00106-france24-france24-samsunguk-qvpp8.amagi.tv/playlist/amg00106-france24-france24-samsunguk/playlist.m3u8',
    page: 'https://www.france24.com/en/live',
  ),
];

MediaChannel mediaChannelFor(String? id) => mediaChannels.firstWhere(
  (channel) => channel.id == id,
  orElse: () => mediaChannels.first,
);
