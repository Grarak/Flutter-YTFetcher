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
  PlaylistsPage(String apiKey, String host, Musicplayer musicplayer,
      PlaylistController playlistController,
      {Key key})
      : super(apiKey, host, musicplayer, playlistController, key: key);

  @override
  State<StatefulWidget> createState() {
    return _PlaylistsPageState();
  }
}

class _PlaylistsPageState extends ParentPageState<PlaylistsPage> {
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();

    gridAxisCount = 1;

    _reload();
  }

  @override
  Widget buildLoadingWidget() {
    return new Container();
  }

  @override
  Widget build(BuildContext context) {
    if (_showLoading) {
      return new Center(child: new CupertinoActivityIndicator());
    }

    return new SafeArea(
      child: new Column(
        children: <Widget>[
          new InputBar(Icons.add, (String text) {
            setState(() {
              _showLoading = true;
            });

            widget.playlistServer
                .create(new Playlist(apikey: widget.apiKey, name: text), () {
              widgets.clear();
              setState(() {
                _showLoading = false;
              });
              _reload();
            }, (int code, Object error) {
              if (code == codes.PlaylistIdAlreadyExists) {
                viewUtils.showMessageDialog(
                    context, "Playlist already exists!");
              } else {
                viewUtils.showServerNoReachable(context);
              }
              setState(() {
                _showLoading = false;
              });
            });
          }, "New playlist"),
          new Expanded(
            child: new Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: buildChildren(),
            ),
          ),
        ],
      ),
    );
  }

  void _reload() {
    setState(() {
      _showLoading = true;
    });

    fetchPlaylist(
      true,
      (List<Playlist> playlists) {
        for (Playlist playlist in playlists) {
          setState(() {
            _showLoading = false;
          });

          widgets.add(
            new PlaylistItem(
              playlist,
              () {
                setState(() {
                  _showLoading = true;
                });

                playlist.apikey = widget.apiKey;
                widget.playlistServer.listIds(
                  playlist,
                  (List<String> ids) {
                    if (ids.isEmpty) {
                      setState(() {
                        _showLoading = false;
                      });
                      viewUtils.showMessageDialog(
                          context, "Playlist is empty!");
                      return;
                    }

                    List<Youtube> youtubes = new List();
                    for (String id in ids) {
                      youtubes.add(new Youtube(apikey: widget.apiKey, id: id));
                    }
                    widget.youtubeServer.getInfoList(
                      youtubes,
                      (List<YoutubeResult> results) {
                        setState(() {
                          _showLoading = false;
                        });

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
                        viewUtils.showServerNoReachable(context);
                        setState(() {
                          _showLoading = false;
                        });
                      },
                    );
                  },
                  (int code, Object error) {
                    viewUtils.showServerNoReachable(context);
                    setState(() {
                      _showLoading = false;
                    });
                  },
                );
              },
              (bool public) {},
              () {
                viewUtils.showOptionsDialog(
                    context, "Delete ${playlist.name}?", null, () {
                  setState(() {
                    _showLoading = true;
                  });
                  playlist.apikey = widget.apiKey;
                  widget.playlistServer.delete(playlist, () {
                    widgets.clear();
                    setState(() {
                      _showLoading = false;
                    });
                    _reload();
                  }, (int code, Object error) {
                    viewUtils.showServerNoReachable(context);
                    setState(() {
                      _showLoading = false;
                    });
                  });
                });
              },
            ),
          );
        }
      },
    );
  }
}
