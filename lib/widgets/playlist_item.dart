import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../api/playlist_server.dart';

class PlaylistItem extends StatelessWidget {
  final Playlist playlist;
  final Function() onTap;
  final Function() onDelete;

  PlaylistItem(this.playlist, this.onTap, this.onDelete);

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: InkWell(
        child: new Padding(
          padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: new Row(
            children: <Widget>[
              new Expanded(
                child: new Text(
                  playlist.name,
                  style: TextStyle(),
                ),
              ),
              new PopupMenuButton<int>(
                padding: EdgeInsets.zero,
                icon: new Icon(Icons.more_vert),
                onSelected: (int selection) {
                  switch (selection) {
                    case 0:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
                      new PopupMenuItem<int>(
                        value: 0,
                        child: new Text("Delete"),
                      ),
                    ],
              ),
            ],
          ),
        ),
        onTap: () {
          onTap();
        },
      ),
    );
  }
}
