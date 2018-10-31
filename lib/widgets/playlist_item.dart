import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../api/playlist_server.dart';

class PlaylistItem extends StatefulWidget {
  final Playlist playlist;
  final Function() onTap;
  final Function(bool public) onPublicChange;

  PlaylistItem(this.playlist, this.onTap, this.onPublicChange);

  @override
  State<StatefulWidget> createState() {
    return new _PlaylistItemState();
  }
}

class _PlaylistItemState extends State<PlaylistItem> {
  @override
  Widget build(BuildContext context) {
    return new Card(
      child: InkWell(
        child: new Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: new Row(
            children: <Widget>[
              new Expanded(
                child: new Text(
                  widget.playlist.name,
                  style: TextStyle(),
                ),
              ),
              new Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: new Text(
                  "Public".toUpperCase(),
                  style: new TextStyle(
                    fontSize: 12.0,
                    color: Colors.black,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              new CupertinoSwitch(
                value: widget.playlist.public,
                onChanged: (bool on) {
                  widget.onPublicChange(on);
                  setState(() {
                    widget.playlist.public = on;
                  });
                },
              ),
            ],
          ),
        ),
        onTap: () {
          widget.onTap();
        },
      ),
    );
  }
}
