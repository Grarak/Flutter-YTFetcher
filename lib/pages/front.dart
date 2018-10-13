import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import '../api/youtube_server.dart';
import '../view_utils.dart' as viewUtils;
import '../widgets/music.dart';
import 'parent.dart';

class FrontPage extends ParentPage<YoutubeServer> {
  FrontPage(String apiKey, Musicplayer musicplayer, String host)
      : super(apiKey, musicplayer, new YoutubeServer(host));

  @override
  State<StatefulWidget> createState() {
    return _FrontPageState();
  }
}

class _MusicListenerImpl implements MusicListener {
  final _FrontPageState state;

  _MusicListenerImpl(this.state);

  @override
  void onDisconnect() {}

  @override
  void onFailure(int code, List<MusicTrack> tracks, int position) {}

  @override
  void onPause(List<MusicTrack> tracks, int position) {}

  @override
  void onPlay(List<MusicTrack> tracks, int position) {}

  @override
  void onPreparing(List<MusicTrack> tracks, int position) {}
}

class _FrontPageState extends ParentPageState<FrontPage> {
  _MusicListenerImpl _listener;

  @override
  void initState() {
    super.initState();

    if (_listener == null) {
      _listener = new _MusicListenerImpl(this);
      widget.musicplayer.addListener(_listener);
    }

    if (widgets.isEmpty) {
      widget.server.getCharts(new Youtube(apiKey: widget.apiKey),
          (List<YoutubeResult> results) {
        widgets = List.generate(results.length, (int index) {
          return new Music(
            results[index],
            horizontal: true,
            onClick: () {
              widget.musicplayer.playTrack(
                  widget.server.host, results[index].toTrack(widget.apiKey));
            },
          );
        });
      }, (int code, Object error) {
        viewUtils.showMessageDialog(context, "Server is not reachable!");
      });
    }
  }
}
