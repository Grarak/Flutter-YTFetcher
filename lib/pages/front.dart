import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import '../api/youtube_server.dart';
import '../view_utils.dart' as viewUtils;
import '../widgets/music.dart';
import 'parent.dart';
import 'playlists.dart';
import '../api/playlist_server.dart';
import '../api/codes.dart' as codes;

class FrontPage extends ParentPage {
  FrontPage(String apiKey, Musicplayer musicplayer, String host,
      PlaylistController playlistController)
      : super(apiKey, host, musicplayer, playlistController);

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
      widget.youtubeServer.getCharts(new Youtube(apikey: widget.apiKey),
          (List<YoutubeResult> results) {
        widgets = List.generate(results.length, (int index) {
          return new Music(
            results[index],
            horizontal: false,
            onClick: () async {
              await widget.musicplayer.playTrack(widget.youtubeServer.host,
                  results[index].toTrack(widget.apiKey));
            },
            onAddPlaylist: () {
              fetchPlaylist(
                false,
                (List<Playlist> playlists) {
                  viewUtils.showListDialog(
                    context,
                    'Select playlist',
                    List.generate(
                      playlists.length,
                      (int index) {
                        return playlists[index].name;
                      },
                    ),
                    (int selected) {
                      widget.playlistServer.addId(
                        new PlaylistId(
                            apikey: widget.apiKey,
                            name: playlists[selected].name,
                            id: results[index].id),
                        () {},
                        (int code, Object error) {
                          if (code == codes.PlaylistIdAlreadyExists) {
                            viewUtils.showMessageDialog(
                                context, "Already in playlist!");
                          } else {
                            viewUtils.showMessageDialog(
                                context, "Server is not reachable!");
                          }
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        });
      }, (int code, Object error) {
        viewUtils.showMessageDialog(context, "Server is not reachable!");
      });
    }
  }
}
