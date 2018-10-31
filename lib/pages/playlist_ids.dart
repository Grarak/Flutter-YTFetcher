import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_list_drag_and_drop/drag_and_drop_list.dart';

import '../api/youtube_server.dart';
import '../widgets/title_bar.dart';

class PlaylistIdsPage extends StatelessWidget {
  final String name;
  final List<YoutubeResult> results;
  final Function(YoutubeResult result) onClick;
  final Function(List<YoutubeResult> results) onShuffle;
  final Function(List<YoutubeResult> results) onPlay;

  PlaylistIdsPage(
      this.name, this.results, this.onClick, this.onShuffle, this.onPlay);

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        accentColor: CupertinoColors.activeBlue,
      ),
      home: new Scaffold(
        body: new Column(
          children: <Widget>[
            new TitleBar(
              title: name,
              rightSide: new Row(
                children: <Widget>[
                  new FloatingActionButton(
                    heroTag: "shuffle",
                    onPressed: () {
                      onShuffle(results);
                    },
                    child: new Icon(Icons.shuffle),
                    mini: true,
                  ),
                  new FloatingActionButton(
                    heroTag: "play",
                    onPressed: () {
                      onPlay(results);
                    },
                    child: new Icon(Icons.play_arrow),
                    mini: true,
                  )
                ],
              ),
              onBackClick: () {
                Navigator.pop(context, false);
              },
            ),
            new Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: new DragAndDropList<YoutubeResult>(results,
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
                              onSelected: (int selection) {
                                switch (selection) {
                                  case 0:
                                    break;
                                  case 1:
                                    break;
                                  case 2:
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
                                  ],
                            ),
                          ],
                        ),
                        onTap: () {
                          onClick(item);
                        },
                      );
                    },
                    onDragFinish: (before, after) {
                      YoutubeResult data = results[before];
                      results.removeAt(before);
                      results.insert(after, data);
                    },
                    canBeDraggedTo: (int oldIndex, int newIndex) => true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
