import 'package:flutter/material.dart';

import '../download_manager.dart';

class DownloadItem extends StatefulWidget {
  final Download _download;
  final Function() onClick;
  final Function() onDelete;

  DownloadItem(this._download, this.onClick, this.onDelete);

  @override
  State<StatefulWidget> createState() {
    return new _DownloadItemState();
  }
}

class _DownloadItemState extends State<DownloadItem> {
  double _progress;

  Widget _buildPopupMenu() {
    return new PopupMenuButton<int>(
      padding: EdgeInsets.zero,
      icon: new Icon(Icons.more_vert),
      onSelected: (int selection) {
        switch (selection) {
          case 0:
            widget.onDelete();
            break;
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuItem<int>>[
            new PopupMenuItem<int>(
              value: 0,
              child: new Text("Delete"),
            ),
          ],
    );
  }

  Widget _buildDetails() {
    List<Widget> widgets = [
      new Text(
        widget._download.youtubeResult.title,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    ];
    if (!widget._download.isDownloaded()) {
      widgets.add(new Container(
        margin: EdgeInsets.only(top: 8.0),
        child: new LinearProgressIndicator(
          value: _progress,
        ),
      ));
    }

    return new Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: widgets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          new Expanded(
            child: _buildDetails(),
          ),
          _buildPopupMenu(),
        ],
      ),
      onTap: () {
        widget.onClick();
      },
    );
  }
}
