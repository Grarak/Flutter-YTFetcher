import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:musicplayer/musicplayer.dart';

import 'main.dart';
import 'pages/front.dart';
import 'pages/playlists.dart';
import 'pages/search.dart';
import 'pages/downloads.dart';
import 'pages/music_control.dart';
import 'pages/settings.dart';
import 'pages/history.dart';
import 'view_utils.dart' as viewUtils;
import 'widgets/music_bar.dart';
import 'utils.dart' as utils;

class NavigationItem {
  IconData icon;
  Widget widget;

  NavigationItem(this.icon, this.widget);
}

class Home extends StatelessWidget {
  final String host;
  final List<NavigationItem> items;

  Home(String apiKey, this.host)
      : items = [
          new NavigationItem(
            Icons.home,
            new FrontPage(
              apiKey,
              host,
              key: new PageStorageKey("Front"),
            ),
          ),
          new NavigationItem(
            Icons.playlist_play,
            new PlaylistsPage(
              apiKey,
              host,
              key: new PageStorageKey("Playlists"),
            ),
          ),
          new NavigationItem(
            Icons.search,
            new SearchPage(
              apiKey,
              host,
              key: new PageStorageKey("Search"),
            ),
          ),
          new NavigationItem(
            Icons.cloud_download,
            new DownloadsPage(
              apiKey,
              host,
              key: new PageStorageKey("Downloads"),
            ),
          ),
          new NavigationItem(
            Icons.settings,
            new SettingsPage(
              (BuildContext context) {
                Navigator.push(context,
                    new CupertinoPageRoute(builder: (BuildContext context) {
                  return new HistoryPage(apiKey, host);
                }));
              },
              (BuildContext context) {
                viewUtils.showOptionsDialog(
                    context, "Do you want to sign out?", null, () {
                  Musicplayer.instance.stop();
                  utils.Settings.setHost(null);
                  utils.Settings.setApiKey(null);
                  Navigator.pushReplacement(context,
                      new CupertinoPageRoute(builder: (BuildContext context) {
                    return new Login();
                  }));
                });
              },
              key: new PageStorageKey("Settings"),
            ),
          ),
        ];

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        primaryColor: CupertinoColors.activeBlue,
        accentColor: CupertinoColors.activeBlue,
      ),
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        child: new HomePage(host, items, Musicplayer.instance),
      ),
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
          child: new CupertinoActivityIndicator(),
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
              return new MusicControl(widget.host);
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
              title: new Text((item.widget.key as PageStorageKey).value),
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
