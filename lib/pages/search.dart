import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import 'parent.dart';
import '../api/youtube_server.dart';
import '../widgets/input_bar.dart';
import '../widgets/music.dart';
import '../view_utils.dart' as viewUtils;
import '../api/playlist_server.dart';
import '../api/codes.dart' as codes;
import '../download_manager.dart';

class SearchPage extends ParentPage {
  SearchPage(String apiKey, String host, {Key key})
      : super(apiKey, host, key: key);

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
  }

  @override
  Widget buildLoadingWidget() {
    return showLoading ? super.buildLoadingWidget() : new Container();
  }

  @override
  EdgeInsets buildListPadding() {
    return EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0);
  }

  @override
  Widget build(BuildContext context) {
    return new SafeArea(
      child: new Column(
        children: <Widget>[
          new InputBar(Icons.search, (String text) {
            widgets.clear();
            widget.youtubeServer.close();
            showLoading = true;

            widget.youtubeServer.search(
              new Youtube(apikey: widget.apiKey, searchquery: text),
              (List<YoutubeResult> results) {
                widgets = List.generate(
                  results.length,
                  (int index) {
                    return new Music(
                      results[index],
                      horizontal: true,
                      onClick: () {
                        Musicplayer.instance.playTrack(
                            widget.host, results[index].toTrack(widget.apiKey));
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
                        downloadManager.queue(context, results[index]);
                      },
                    );
                  },
                );

                if (results.length == 0) {
                  viewUtils.showMessageDialog(context, "No results found");
                }

                showLoading = false;
              },
              (int code, Object error) {
                viewUtils.showServerNoReachable(context);
                showLoading = false;
              },
            );
          }, "Search"),
          new Expanded(
            child: buildChildren(),
          ),
        ],
      ),
    );
  }
}
