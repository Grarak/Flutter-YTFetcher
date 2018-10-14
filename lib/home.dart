import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import 'pages/front.dart';
import 'pages/playlists.dart';
import 'view_utils.dart';
import 'widgets/music_bar.dart';

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

class _HomePageState extends State<HomePage> implements MusicListener {
  int current = 0;
  MusicTrack currentTrack;
  PlayingState currentState;

  @override
  void initState() {
    super.initState();

    widget.musicplayer.listener = this;

    WidgetsBinding.instance
        .addObserver(new LifecycleEventHandler(resumeCallBack: () {
      widget.musicplayer.listener = this;
    }, suspendingCallBack: () {
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
        body: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Expanded(
              child: widget.items[current].widget,
            ),
            new MusicBar(currentTrack, currentState, () {
              widget.musicplayer.resume();
            }, () {
              widget.musicplayer.pause();
            }, () {}),
          ],
        ),
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
      ),
    );
  }

  @override
  void onStateChanged(
      PlayingState state, List<MusicTrack> tracks, int position) {
    print(state.toString() + " " + tracks[position].title);
    setState(() {
      currentTrack = tracks[position];
      currentState = state;
    });
  }

  @override
  void onFailure(int code, List<MusicTrack> tracks, int position) {
    onDisconnect();
  }

  @override
  void onDisconnect() {
    print("onDisconnect");
    setState(() {
      currentTrack = null;
      currentState = null;
    });
  }
}
