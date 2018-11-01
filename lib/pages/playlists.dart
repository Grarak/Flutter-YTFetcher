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
import '../api/codes.dart' as codes;

class PlaylistController {
  List<Playlist> _playlists = new List();

  List<Playlist> get playlists => _playlists;
}

class PlaylistsPage extends ParentPage {
  final YoutubeServer _youtubeServer;

  PlaylistsPage(String apiKey, Musicplayer musicplayer, String host,
      PlaylistController playlistController)
      : _youtubeServer = new YoutubeServer(host),
        super(apiKey, host, musicplayer, playlistController);

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

    _reload();
  }

  void _reload() {
    if (widgets.isEmpty) {
      widgets.add(new InputBar(Icons.add, (String text) {
        showLoading = true;
        widget.playlistServer
            .create(new Playlist(apikey: widget.apiKey, name: text), () {
          widgets.clear();
          showLoading = false;
          _reload();
        }, (int code, Object error) {
          if (code == codes.PlaylistIdAlreadyExists) {
            viewUtils.showMessageDialog(context, "Playlist already exists!");
          } else {
            viewUtils.showMessageDialog(context, "Server is not reachable!");
          }
          showLoading = false;
        });
      }, "New playlist"));
    }

    if (widgets.length == 1) {
      fetchPlaylist(
        true,
        (List<Playlist> playlists) {
          for (Playlist playlist in playlists) {
            widgets.add(new PlaylistItem(
              playlist,
              () {
                showLoading = true;

                playlist.apikey = widget.apiKey;
                widget.playlistServer.listIds(
                  playlist,
                  (List<String> ids) {
                    if (ids.isEmpty) {
                      showLoading = false;
                      viewUtils.showMessageDialog(
                          context, "Playlist is empty!");
                      return;
                    }

                    List<Youtube> youtubes = new List();
                    for (String id in ids) {
                      youtubes.add(new Youtube(apikey: widget.apiKey, id: id));
                    }
                    widget._youtubeServer.getInfoList(
                      youtubes,
                      (List<YoutubeResult> results) {
                        showLoading = false;

                        Navigator.push(context, new CupertinoPageRoute(
                            builder: (BuildContext context) {
                          return new PlaylistIds(
                              widget.host,
                              widget.musicplayer,
                              widget.playlistController,
                              playlist,
                              results);
                        }));
                      },
                      (int code, Object error) {
                        viewUtils.showMessageDialog(
                            context, "Server is not reachable!");
                        showLoading = false;
                      },
                    );
                  },
                  (int code, Object error) {
                    viewUtils.showMessageDialog(
                        context, "Server is not reachable!");
                    showLoading = false;
                  },
                );
              },
              (bool public) {},
              () {
                viewUtils.showOptionsDialog(
                    context, "Delete ${playlist.name}?", null, () {
                  showLoading = true;
                  playlist.apikey = widget.apiKey;
                  widget.playlistServer.delete(playlist, () {
                    widgets.clear();
                    showLoading = false;
                    _reload();
                  }, (int code, Object error) {
                    viewUtils.showMessageDialog(
                        context, "Server is not reachable!");
                    showLoading = false;
                  });
                });
              },
            ));
          }
        },
      );
    }
  }
}
