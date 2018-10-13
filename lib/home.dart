import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import 'pages/front.dart';
import 'pages/playlists.dart';
import 'view_utils.dart';

class NavigationItem {
  String title;
  IconData icon;
  Widget widget;

  NavigationItem(this.title, this.icon, this.widget);
}

class Home extends StatelessWidget {
  final List<NavigationItem> items = new List();
  final Musicplayer musicplayer = new Musicplayer();

  Home(String apiKey, String host) {
    items.add(new NavigationItem(
        "Front", Icons.home, new FrontPage(apiKey, musicplayer, host)));
    items.add(new NavigationItem(
        "Playlists", Icons.playlist_play, new PlaylistsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: new HomePage(items, musicplayer),
    );
  }
}

class HomePage extends StatefulWidget {
  final List<NavigationItem> items;
  final Musicplayer musicplayer;

  HomePage(this.items, this.musicplayer);

  @override
  State<StatefulWidget> createState() {
    return new _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  int current = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addObserver(new LifecycleEventHandler(suspendingCallBack: () {
      widget.musicplayer.unbind();
    }));
  }

  @override
  Widget build(BuildContext context) {
    if (widget == null) {
      return new Scaffold(
        body: new Center(
          child: new CircularProgressIndicator(),
        ),
      );
    }

    return new MaterialApp(
        home: new Scaffold(
      body: widget.items[current].widget,
      bottomNavigationBar: new BottomNavigationBar(
        onTap: (int index) {
          setState(() {
            current = index;
          });
        },
        currentIndex: current,
        items: List.generate(widget.items.length, (int index) {
          NavigationItem item = widget.items[index];
          return new BottomNavigationBarItem(
            icon: new Icon(item.icon),
            title: new Text(item.title),
          );
        }),
      ),
    ));
  }
}
