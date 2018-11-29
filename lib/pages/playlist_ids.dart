import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_list_drag_and_drop/drag_and_drop_list.dart';
import 'package:musicplayer/musicplayer.dart';

import '../api/youtube_server.dart';
import '../widgets/title_bar.dart';
import 'parent.dart';
import 'playlists.dart';
import '../view_utils.dart' as viewUtils;
import '../api/playlist_server.dart';
import '../download_manager.dart';

class PlaylistIds extends StatelessWidget {
  final String host;
  final Musicplayer musicplayer;
  final PlaylistController playlistController;
  final Playlist playlist;
  final List<YoutubeResult> results;

  PlaylistIds(this.host, this.musicplayer, this.playlistController,
      this.playlist, this.results);

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        accentColor: CupertinoColors.activeBlue,
      ),
      home: new _PlaylistIdsPage(
          host, musicplayer, playlistController, playlist, results, () {
        Navigator.pop(context, false);
      }),
    );
  }
}

class _PlaylistIdsPage extends ParentPage {
  final Playlist playlist;
  final List<YoutubeResult> results;
  final Function() onBackClick;

  _PlaylistIdsPage(
      String host,
      Musicplayer musicplayer,
      PlaylistController controller,
      this.playlist,
      this.results,
      this.onBackClick)
      : super(playlist.apikey, host, musicplayer, controller);

  @override
  State<StatefulWidget> createState() {
    return new _PlaylistIdsPageState(onBackClick);
  }
}

class _PlaylistIdsPageState extends State<_PlaylistIdsPage> {
  final Function() onBackClick;
  bool needsUpdate = false;

  _PlaylistIdsPageState(this.onBackClick);

  void setIds() {
    if (!needsUpdate) {
      return;
    }

    widget.playlistServer.setIds(
      widget.playlist,
      List.generate(widget.results.length, (int index) {
        return widget.results[index].id;
      }),
      () {},
      (int code, Object error) {},
    );

    needsUpdate = false;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(new viewUtils.LifecycleEventHandler(
        resumeCallBack: () {},
        suspendingCallBack: () {
          setIds();
        }));
  }

  @override
  void dispose() {
    super.dispose();

    setIds();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Column(
        children: <Widget>[
          new TitleBar(
            title: widget.playlist.name,
            rightSide: new Row(
              children: <Widget>[
                new FloatingActionButton(
                  heroTag: "download",
                  onPressed: () async {
                    DownloadManager downloadManager =
                        await DownloadManager.instance;
                    for (YoutubeResult result in widget.results) {
                      downloadManager.queue(result);
                    }
                  },
                  child: new Icon(Icons.file_download),
                  mini: true,
                ),
                new FloatingActionButton(
                  heroTag: "shuffle",
                  onPressed: () {
                    List<MusicTrack> shuffled = List.generate(
                      widget.results.length,
                      (int index) {
                        return widget.results[index].toTrack(widget.apiKey);
                      },
                    );
                    shuffled.shuffle();
                    widget.musicplayer.playTracks(widget.host, shuffled, 0);
                  },
                  child: new Icon(Icons.shuffle),
                  mini: true,
                ),
                new FloatingActionButton(
                  heroTag: "play",
                  onPressed: () {
                    widget.musicplayer.playTracks(
                        widget.host,
                        List.generate(
                          widget.results.length,
                          (int index) {
                            return widget.results[index].toTrack(widget.apiKey);
                          },
                        ),
                        0);
                  },
                  child: new Icon(Icons.play_arrow),
                  mini: true,
                )
              ],
            ),
            onBackClick: () {
              onBackClick();
            },
          ),
          new Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: new DragAndDropList<YoutubeResult>(widget.results,
                  itemBuilder: (BuildContext context, item) {
                    return new InkWell(
                      child: new Row(
                        children: <Widget>[
                          new Expanded(
                            child: new Padding(
                              padding: EdgeInsets.only(
                                  left: 16.0, top: 8.0, bottom: 8.0),
                              child: new Text(item.title),
                            ),
                          ),
                          new PopupMenuButton<int>(
                            padding: EdgeInsets.zero,
                            icon: new Icon(Icons.more_vert),
                            onSelected: (int selection) async {
                              switch (selection) {
                                case 0:
                                  setState(() {
                                    needsUpdate = true;
                                    widget.results.remove(item);
                                  });
                                  break;
                                case 1:
                                  int index = widget.results.indexOf(item);
                                  if (index - 1 >= 0) {
                                    setState(() {
                                      needsUpdate = true;
                                      widget.results[index] =
                                          widget.results[index - 1];
                                      widget.results[index - 1] = item;
                                    });
                                  }
                                  break;
                                case 2:
                                  int index = widget.results.indexOf(item);
                                  if (index + 1 < widget.results.length) {
                                    setState(() {
                                      needsUpdate = true;
                                      widget.results[index] =
                                          widget.results[index + 1];
                                      widget.results[index + 1] = item;
                                    });
                                  }
                                  break;
                                case 3:
                                  DownloadManager downloadManager =
                                      await DownloadManager.instance;
                                  if (!downloadManager.queue(item)) {
                                    viewUtils.showMessageDialog(
                                        context, "Already downloaded");
                                  }
                                  break;
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuItem<int>>[
                                  new PopupMenuItem<int>(
                                    value: 0,
                                    child: new Text("Remove from playlist"),
                                  ),
                                  new PopupMenuItem(
                                    value: 1,
                                    child: new Text("Move up"),
                                  ),
                                  new PopupMenuItem(
                                    value: 2,
                                    child: new Text("Move down"),
                                  ),
                                  new PopupMenuItem(
                                    value: 3,
                                    child: new Text("Download"),
                                  ),
                                ],
                          ),
                        ],
                      ),
                      onTap: () {
                        widget.musicplayer.playTrack(widget.playlistServer.host,
                            item.toTrack(widget.apiKey));
                      },
                    );
                  },
                  onDragFinish: (before, after) {
                    YoutubeResult data = widget.results[before];
                    widget.results.removeAt(before);
                    widget.results.insert(after, data);
                    needsUpdate = true;
                  },
                  canBeDraggedTo: (int oldIndex, int newIndex) => true),
            ),
          ),
        ],
      ),
    );
  }
}
