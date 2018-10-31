import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:musicplayer/musicplayer.dart';

import 'pages/front.dart';
import 'pages/playlists.dart';
import 'pages/search.dart';
import 'pages/music_control.dart';
import 'view_utils.dart' as viewUtils;
import 'widgets/music_bar.dart';

class NavigationItem {
  String title;
  IconData icon;
  Widget widget;

  NavigationItem(this.title, this.icon, this.widget);
}

class Home extends StatelessWidget {
  final String host;
  final List<NavigationItem> items = new List();
  final Musicplayer musicplayer = new Musicplayer();

  Home(String apiKey, this.host) {
    items.add(new NavigationItem(
        "Front", Icons.home, new FrontPage(apiKey, musicplayer, host)));
    items.add(new NavigationItem("Playlists", Icons.playlist_play,
        new PlaylistsPage(apiKey, musicplayer, host)));
    items.add(new NavigationItem(
        "Search", Icons.search, new SearchPage(apiKey, musicplayer, host)));
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        accentColor: CupertinoColors.activeBlue,
      ),
      home: new HomePage(host, items, musicplayer),
    );
  }
}

class HomePage extends StatefulWidget {
  final String host;
  final List<NavigationItem> items;
  final Musicplayer musicplayer;

  HomePage(this.host, this.items, this.musicplayer);

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

    widget.musicplayer.addListener(this);

    WidgetsBinding.instance
        .addObserver(new viewUtils.LifecycleEventHandler(resumeCallBack: () {
      widget.musicplayer.addListener(this);
    }, suspendingCallBack: () {
      widget.musicplayer.unbind();
      widget.musicplayer.removeListener(this);
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

    return new Scaffold(
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
          }, () {
            Navigator.push(context,
                new CupertinoPageRoute(builder: (BuildContext context) {
              return new MusicControl(widget.host, widget.musicplayer);
            }));
          }),
        ],
      ),
      bottomNavigationBar: new CupertinoTabBar(
        onTap: (int index) {
          setState(() {
            current = index;
          });
        },
        currentIndex: current,
        items: List.generate(
          widget.items.length,
          (int index) {
            NavigationItem item = widget.items[index];
            return new BottomNavigationBarItem(
              icon: new Icon(item.icon),
              title: new Text(item.title),
            );
          },
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
    print(PlayingState.FAILED.toString() + " " + tracks[position].title);
    if (mounted) {
      setState(() {
        currentTrack = tracks[position];
        currentState = PlayingState.FAILED;
      });
    }
  }

  @override
  void onDisconnect() {
    if (mounted) {
      setState(() {
        currentTrack = null;
        currentState = null;
      });
    }
  }
}
