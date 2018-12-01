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
import '../download_manager.dart';

class SearchPage extends ParentPage {
  SearchPage(String apiKey, String host, Musicplayer musicplayer,
      PlaylistController playlistController,
      {Key key})
      : super(apiKey, host, musicplayer, playlistController, key: key);

  @override
  State<StatefulWidget> createState() {
    return new _SearchPageState();
  }
}

class _SearchPageState extends ParentPageState<SearchPage> {
  bool _showLoading = false;

  @override
  void initState() {
    super.initState();

    gridAxisCount = 1;
  }

  @override
  Widget buildLoadingWidget() {
    return _showLoading ? super.buildLoadingWidget() : new Container();
  }

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      child: new Column(
        children: <Widget>[
          new InputBar(Icons.search, (String text) {
            widget.youtubeServer.close();
            setState(() {
              _showLoading = true;
            });

            widget.youtubeServer.search(
              new Youtube(apikey: widget.apiKey, searchquery: text),
              (List<YoutubeResult> results) {
                widgets.clear();
                for (YoutubeResult result in results) {
                  widgets.add(
                    new Music(
                      result,
                      horizontal: true,
                      onClick: () {
                        widget.musicplayer.playTrack(
                            widget.host, result.toTrack(widget.apiKey));
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
                                      viewUtils.showServerNoReachable(context);
                                    }
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                      onDownload: () async {
                        DownloadManager downloadManager =
                            await DownloadManager.instance;
                        downloadManager.queue(context, result);
                      },
                    ),
                  );
                }

                setState(() {
                  _showLoading = false;
                });
              },
              (int code, Object error) {
                viewUtils.showServerNoReachable(context);
                setState(() {
                  _showLoading = false;
                });
              },
            );
          }, "Search"),
          new Expanded(
            child: new Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: buildChildren(),
            ),
          ),
        ],
      ),
    );
  }
}
