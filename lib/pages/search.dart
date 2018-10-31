import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import 'parent.dart';
import '../api/youtube_server.dart';
import '../widgets/input_bar.dart';
import '../widgets/music.dart';
import '../view_utils.dart' as viewUtils;

class SearchPage extends ParentPage<YoutubeServer> {
  SearchPage(String apiKey, Musicplayer musicplayer, String host)
      : super(apiKey, musicplayer, new YoutubeServer(host));

  @override
  State<StatefulWidget> createState() {
    return new _SearchPageState();
  }
}

class _SearchPageState extends ParentPageState<SearchPage> {
  @override
  void initState() {
    super.initState();

    gridAxisCount = 1;

    if (widgets.isEmpty) {
      widgets.add(new InputBar(Icons.search, (String text) {
        widget.server.close();
        showLoading = true;

        widget.server
            .search(new Youtube(apikey: widget.apiKey, searchquery: text),
                (List<YoutubeResult> results) {
          for (YoutubeResult result in results) {
            widgets.add(
              new Music(
                result,
                horizontal: true,
                onClick: () {
                  widget.musicplayer.playTrack(
                      widget.server.host, result.toTrack(widget.apiKey));
                },
                onAddPlaylist: () {},
              ),
            );
          }

          showLoading = false;
        }, (int code, Object error) {
          viewUtils.showMessageDialog(context, "Server is not reachable!");
          showLoading = false;
        });
      }, "Search"));
    }
  }
}
