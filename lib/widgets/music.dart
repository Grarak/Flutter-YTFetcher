import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../api/youtube_server.dart';

class Music extends StatelessWidget {
  final YoutubeResult result;
  final bool horizontal;
  final Function() onClick;
  final Function() onAddPlaylist;
  final Function() onDownload;

  Music(this.result,
      {Key key,
      this.horizontal = false,
      this.onClick,
      this.onAddPlaylist,
      this.onDownload})
      : super(key: key);

  Widget _buildImage() {
    return new Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: new Material(
        child: new Stack(
          children: <Widget>[
            new Material(
              elevation: -16.0,
              child: new Ink.image(
                image: new CachedNetworkImageProvider(result.thumbnail),
                fit: BoxFit.cover,
                child: new InkWell(
                  onTap: () {
                    if (onClick != null) {
                      onClick();
                    }
                  },
                ),
              ),
            ),
            new Align(
              alignment: Alignment(1.0, 1.0),
              child: new Container(
                height: 20.0,
                margin: EdgeInsets.all(6.0),
                width: 50.0,
                color: new Color(0x80000000),
                child: new Center(
                  child: new Text(
                    result.duration,
                    style: new TextStyle(fontSize: 12.0, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        elevation: 4.0,
      ),
    );
  }

  Widget _buildPopupMenu() {
    return new PopupMenuButton<int>(
      padding: EdgeInsets.zero,
      icon: new Icon(Icons.more_vert),
      onSelected: (int selection) {
        switch (selection) {
          case 0:
            if (onAddPlaylist != null) {
              onAddPlaylist();
            }
            break;
          case 1:
            if (onDownload != null) {
              onDownload();
            }
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
            new PopupMenuItem<int>(
              value: 0,
              child: new Text("Add to playlist"),
            ),
            new PopupMenuItem(
              value: 1,
              child: new Text("Download"),
            ),
          ],
    );
  }

  Widget _buildHorizontal() {
    return new AspectRatio(
      aspectRatio: 3.2,
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          new Expanded(
            child: _buildImage(),
          ),
          new Expanded(
            child: new Row(
              children: <Widget>[
                new Expanded(
                  child: new Center(
                    child: new Text(
                      result.title,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                _buildPopupMenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVertical() {
    return new Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        new Expanded(
          child: _buildImage(),
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
              _buildPopupMenu(),
            ],
          ),
          flex: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return horizontal ? _buildHorizontal() : _buildVertical();
  }
}
