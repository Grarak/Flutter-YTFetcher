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
    return new _FrontPageState();
  }
}

class _FrontPageState extends ParentPageState<FrontPage> {
  @override
  void initState() {
    super.initState();

    if (widgets.isEmpty) {
      widget.server.getCharts(new Youtube(apiKey: widget.apiKey),
          (List<YoutubeResult> results) {
        widgets = List.generate(results.length, (int index) {
          return new Music(
            results[index],
            horizontal: true,
            onClick: () async {
              await widget.musicplayer.playTrack(
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
