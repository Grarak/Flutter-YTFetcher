import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:musicplayer/musicplayer.dart';

import '../api/playlist_server.dart';
import '../api/youtube_server.dart';
import 'parent.dart';
import '../widgets/input_bar.dart';
import '../widgets/playlist_item.dart';
import '../view_utils.dart' as viewUtils;
import 'playlist_ids.dart';

class PlaylistsPage extends ParentPage<PlaylistServer> {
  final YoutubeServer youtubeServer;

  PlaylistsPage(String apiKey, Musicplayer musicplayer, String host)
      : youtubeServer = new YoutubeServer(host),
        super(apiKey, musicplayer, new PlaylistServer(host));

  @override
  State<StatefulWidget> createState() {
    return _PlaylistsPageState();
  }
}

class _PlaylistsPageState extends ParentPageState<PlaylistsPage> {
  @override
  void initState() {
    super.initState();

    gridAxisCount = 1;

    if (widgets.isEmpty) {
      widgets.add(new InputBar(Icons.add, (String text) {}, "New playlist"));
    }

    if (widgets.length == 1) {
      showLoading = true;
      widget.server.list(widget.apiKey, (List<Playlist> playlists) {
        for (Playlist playlist in playlists) {
          widgets.add(new PlaylistItem(playlist, () {
            showLoading = true;

            playlist.apikey = widget.apiKey;
            widget.server.listIds(playlist, (List<String> ids) {
              List<Youtube> youtubes = new List();
              for (String id in ids) {
                youtubes.add(new Youtube(apikey: widget.apiKey, id: id));
              }
              widget.youtubeServer.getInfoList(youtubes,
                  (List<YoutubeResult> results) {
                showLoading = false;

                Navigator.push(context,
                    new CupertinoPageRoute(builder: (BuildContext context) {
                  return new PlaylistIdsPage(playlist.name, results,
                      (YoutubeResult result) {
                    widget.musicplayer.playTrack(
                        widget.server.host, result.toTrack(widget.apiKey));
                  }, (List<YoutubeResult> results) {
                    List<MusicTrack> shuffled = new List(results.length);
                    for (int i = 0; i < results.length; i++) {
                      shuffled[i] = results[i].toTrack(widget.apiKey);
                    }
                    shuffled.shuffle();
                    widget.musicplayer
                        .playTracks(widget.server.host, shuffled, 0);
                  }, (List<YoutubeResult> results) {
                    List<MusicTrack> shuffled = new List(results.length);
                    for (int i = 0; i < results.length; i++) {
                      shuffled[i] = results[i].toTrack(widget.apiKey);
                    }
                    widget.musicplayer
                        .playTracks(widget.server.host, shuffled, 0);
                  });
                }));
              }, (int code, Object error) {
                viewUtils.showMessageDialog(
                    context, "Server is not reachable!");
                showLoading = false;
              });
            }, (int code, Object error) {
              viewUtils.showMessageDialog(context, "Server is not reachable!");
              showLoading = false;
            });
          }, (bool public) {}));
        }
        showLoading = false;
      }, (int code, Object error) {
        viewUtils.showMessageDialog(context, "Server is not reachable!");
        showLoading = false;
      });
    }
  }
}
