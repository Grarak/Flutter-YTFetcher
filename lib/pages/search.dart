import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import 'parent.dart';
import '../api/youtube_server.dart';
import '../widgets/input_bar.dart';
import '../widgets/music.dart';
import '../view_utils.dart' as viewUtils;
import 'playlists.dart';
import '../api/playlist_server.dart';
import '../api/codes.dart' as codes;

class SearchPage extends ParentPage {
  SearchPage(String apiKey, Musicplayer musicplayer, String host,
      PlaylistController playlistController)
      : super(apiKey, host, musicplayer, playlistController);

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
        widget.youtubeServer.close();
        showLoading = true;

        widget.youtubeServer
            .search(new Youtube(apikey: widget.apiKey, searchquery: text),
                (List<YoutubeResult> results) {
          for (YoutubeResult result in results) {
            widgets.add(
              new Music(
                result,
                horizontal: true,
                onClick: () {
                  widget.musicplayer
                      .playTrack(widget.host, result.toTrack(widget.apiKey));
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
                                id: result.id),
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
