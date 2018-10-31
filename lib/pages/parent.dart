import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import '../api/server.dart';

abstract class ParentPage<S extends Server> extends StatefulWidget {
  final String apiKey;
  final Musicplayer musicplayer;
  final S server;

  ParentPage(this.apiKey, this.musicplayer, this.server, {Key key})
      : super(key: key);
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

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: widgets.isEmpty || _showLoading
          ? new Center(child: new CircularProgressIndicator())
          : _gridAxisCount <= 1
              ? ListView(
                  children: _widgets,
                )
              : new GridView.count(
                  crossAxisCount: _gridAxisCount,
                  children: _widgets,
                ),
    );
  }
}
