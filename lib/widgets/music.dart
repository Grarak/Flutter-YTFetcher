import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../api/youtube_server.dart';

class Music extends StatelessWidget {
  final YoutubeResult result;
  final bool horizontal;
  final Function() onClick;
  final Function() onAddPlaylist;

  Music(this.result,
      {Key key, this.horizontal = false, this.onClick, this.onAddPlaylist})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        new Expanded(
          child: new Padding(
            padding: EdgeInsets.all(8.0),
            child: Material(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4.0))),
              child: Ink.image(
                image: CachedNetworkImageProvider(result.thumbnail),
                fit: BoxFit.cover,
                child: InkWell(
                  onTap: () {
                    if (onClick != null) {
                      onClick();
                    }
                  },
                ),
              ),
            ),
          ),
          flex: 3,
        ),
        new Expanded(
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Expanded(
                child: new Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: new Text(
                    result.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              new PopupMenuButton<int>(
                  padding: EdgeInsets.zero,
                  icon: new Icon(Icons.more_vert),
                  onSelected: (int selection) {
                    switch (selection) {
                      case 0:
                        if (onAddPlaylist != null) {
                          onAddPlaylist();
                        }
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
                        PopupMenuItem<int>(
                          value: 0,
                          child: const Text("Add to playlist"),
                        ),
                      ]),
            ],
          ),
          flex: 1,
        ),
      ],
    );
  }
}
