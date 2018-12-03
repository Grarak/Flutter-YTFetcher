import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'playlists.dart';
import '../api/playlist_server.dart';
import '../api/youtube_server.dart';
import '../api/user_server.dart';
import '../api/history_server.dart';
import '../view_utils.dart' as viewUtils;

abstract class ParentPage extends StatefulWidget {
  final String apiKey;
  final String host;
  final PlaylistServer playlistServer;
  final YoutubeServer youtubeServer;
  final UserServer userServer;
  final HistoryServer historyServer;

  ParentPage(this.apiKey, this.host, {Key key})
      : playlistServer = new PlaylistServer(host),
        youtubeServer = new YoutubeServer(host),
        userServer = new UserServer(host),
        historyServer = new HistoryServer(host),
        super(key: key);
}

abstract class ParentPageState<T extends ParentPage> extends State<T>
    with TickerProviderStateMixin {
  int _gridAxisCount = 2;
  List<Widget> _widgets = new List();
  bool _showLoading = false;

  bool get showLoading => _showLoading;

  set showLoading(bool loading) {
    if (mounted) {
      setState(() {
        _showLoading = loading;
      });
    }
  }

  int get gridAxisCount => _gridAxisCount;

  set gridAxisCount(int count) {
    if (mounted) {
      setState(() {
        _gridAxisCount = count;
      });
    }
  }

  List<Widget> get widgets => _widgets;

  set widgets(List<Widget> widgets) {
    if (mounted) {
      setState(() {
        _widgets = widgets;
      });
    }
  }

  void fetchPlaylist(bool clearCache, onSuccess(List<Playlist> playlists)) {
    widget.playlistServer.close();
    if (clearCache) {
      PlaylistController.playlists.clear();
    }

    if (PlaylistController.playlists.isEmpty) {
      showLoading = true;
      widget.playlistServer.list(widget.apiKey, (List<Playlist> playlists) {
        PlaylistController.playlists.clear();
        PlaylistController.playlists.addAll(playlists);
        onSuccess(playlists);
        showLoading = false;
      }, (int code, Object error) {
        viewUtils.showServerNoReachable(context);
        showLoading = false;
      });
    } else {
      onSuccess(PlaylistController.playlists);
    }
  }

  Widget buildLoadingWidget() {
    return new CupertinoActivityIndicator();
  }

  EdgeInsets buildListPadding() {
    return null;
  }

  Widget buildChildren() {
    return widgets.isEmpty || _showLoading
        ? new Center(child: buildLoadingWidget())
        : _gridAxisCount <= 1
            ? ListView(
                children: _widgets,
                physics: new BouncingScrollPhysics(),
                padding: buildListPadding(),
              )
            : new GridView.count(
                crossAxisCount: _gridAxisCount,
                children: _widgets,
                physics: new BouncingScrollPhysics(),
                padding: buildListPadding(),
              );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(body: buildChildren());
  }
}
