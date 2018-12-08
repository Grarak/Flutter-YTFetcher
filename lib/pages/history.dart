import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import 'parent.dart';
import '../widgets/music.dart';
import '../api/playlist_server.dart';
import '../api/youtube_server.dart';
import '../view_utils.dart' as viewUtils;
import '../download_manager.dart';
import '../api/codes.dart' as codes;

class HistoryPage extends ParentPage {
  HistoryPage(String apiKey, String host) : super(apiKey, host);

  @override
  State<StatefulWidget> createState() {
    return new _HistoryPageState();
  }
}

class _HistoryPageState extends ParentPageState<HistoryPage> {
  double progressMax;
  double progress;

  @override
  Widget buildLoadingWidget() {
    return progressMax == null || progress == null
        ? super.buildLoadingWidget()
        : new Center(
            child: new Padding(
              padding: EdgeInsets.all(16.0),
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new Padding(
                    padding: EdgeInsets.all(8.0),
                    child: new Text(
                      "Loading",
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ),
                  new LinearProgressIndicator(
                    value: progress / progressMax,
                  ),
                ],
              ),
            ),
          );
  }

  @override
  EdgeInsets buildListPadding() {
    return EdgeInsets.symmetric(vertical: 8.0);
  }

  @override
  void initState() {
    super.initState();

    gridAxisCount = 1;

    if (widgets.length == 0) {
      widget.historyServer.retrieve(widget.apiKey, (List<String> ids) {
        List<Youtube> youtubes = new List();
        for (String id in ids) {
          youtubes.add(new Youtube(apikey: widget.apiKey, id: id));
        }

        if (ids.length == 0) {
          viewUtils.showMessageDialogCallback(context, "History is empty", () {
            Navigator.pop(context);
          });
        }
        widget.youtubeServer.getInfoList(
          youtubes,
          (List<YoutubeResult> results) {
            widgets = List.generate(results.length, (int index) {
              return new Music(results[index], onClick: () async {
                await Musicplayer.instance.playTrack(widget.youtubeServer.host,
                    results[index].toTrack(widget.apiKey));
              }, onAddPlaylist: () {
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
              }, onDownload: () async {
                DownloadManager downloadManager =
                    await DownloadManager.instance;
                downloadManager.queue(context, results[index]);
              }, horizontal: true);
            });
          },
          (int code, Object error) {
            viewUtils.showServerNoReachableCallback(context, () {
              Navigator.pop(context);
            });
          },
          (int progress) {
            setState(() {
              progressMax = youtubes.length.toDouble();
              this.progress = progress.toDouble();
            });
          },
        );
      }, (int code, Object error) {
        viewUtils.showServerNoReachableCallback(context, () {
          Navigator.pop(context);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text("History"),
        leading: new BackButton(),
      ),
      body: buildChildren(),
    );
  }
}
