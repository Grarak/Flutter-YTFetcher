import 'package:flutter/material.dart';

import '../api/server.dart';

abstract class ParentPage<S extends Server> extends StatefulWidget {
  final String apiKey;
  final S server;

  ParentPage(this.apiKey, this.server, {Key key}) : super(key: key);
}

abstract class ParentPageState<T extends ParentPage> extends State<T> {
  int _gridAxisCount = 2;
  List<Widget> _widgets = new List();

  int get gridAxisCount => _gridAxisCount;

  set gridAxisCount(int count) {
    setState(() {
      _gridAxisCount = count;
    });
  }

  List<Widget> get widgets => _widgets;

  set widgets(List<Widget> widgets) {
    setState(() {
      _widgets = widgets;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: widgets.isEmpty
          ? new Center(child: new CircularProgressIndicator())
          : new GridView.count(
              crossAxisCount: _gridAxisCount,
              children: _widgets,
            ),
    );
  }
}
