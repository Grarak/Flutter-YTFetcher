import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:musicplayer/musicplayer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../view_utils.dart' as viewUtils;
import '../utils.dart' as utils;

class MusicControl extends StatelessWidget {
  final String host;

  MusicControl(this.host);

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      theme: new ThemeData(
        accentColor: CupertinoColors.activeBlue,
      ),
      home: new _MusicControlPage(
        host,
        () {
          Navigator.pop(context, false);
        },
      ),
    );
  }
}

class _MusicControlPage extends StatefulWidget {
  final String host;
  final Function() onBackClick;

  _MusicControlPage(this.host, this.onBackClick);

  @override
  State<StatefulWidget> createState() {
    return new _MusicControlPageState();
  }
}

class _MusicControlPageState extends State<_MusicControlPage>
    implements MusicListener {
  PlayingState _state;
  List<MusicTrack> _tracks;
  int _currentPosition;

  PageController _pageController;

  @override
  void initState() {
    super.initState();

    Musicplayer.instance.addListener(this);

    WidgetsBinding.instance
        .addObserver(new viewUtils.LifecycleEventHandler(resumeCallBack: () {
      Musicplayer.instance.addListener(this);
    }, suspendingCallBack: () {
      Musicplayer.instance.unbind();
      Musicplayer.instance.removeListener(this);
    }));
  }

  @override
  void didUpdateWidget(_MusicControlPage oldWidget) {
    _pageController?.jumpToPage(_currentPosition);

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();

    Musicplayer.instance.removeListener(this);
  }

  Widget _trackBuilder(MusicTrack currentTrack) {
    List<String> titles = currentTrack.getFormattedTitle();

    return new Column(
      children: <Widget>[
        new Expanded(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: new Text(
                  titles[0],
                  textAlign: TextAlign.center,
                  style: new TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              new Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: new Text(
                  titles[1],
                  textAlign: TextAlign.center,
                  style: new TextStyle(
                    fontSize: 15.0,
                  ),
                ),
              ),
            ],
          ),
          flex: 1,
        ),
        new Expanded(
          child: new PageView.builder(
            itemBuilder: (BuildContext context, int index) {
              return new Container(
                padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 45.0),
                child: new Material(
                  elevation: 5.0,
                  child: new CachedNetworkImage(
                    imageUrl: _tracks[index].thumbnail,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
            itemCount: _tracks.length,
            controller: _pageController == null
                ? _pageController = new PageController(
                    initialPage: _currentPosition,
                    viewportFraction: 0.75,
                  )
                : _pageController,
            onPageChanged: (int page) {
              if (page != _currentPosition) {
                Musicplayer.instance.playTracks(widget.host, _tracks, page);
              }
            },
          ),
          flex: 2,
        ),
      ],
    );
  }

  Widget _buildControls() {
    if (_state == PlayingState.PREPARING) {
      return new Center(
        child: new CupertinoActivityIndicator(),
      );
    }

    return new Padding(
      padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
      child: new Column(
        children: <Widget>[
          new Expanded(
            child: new Center(
              child: new _Seek(
                  Musicplayer.instance, _state == PlayingState.PLAYING),
            ),
            flex: 1,
          ),
          new Expanded(
            child: new Center(
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  new IconButton(
                    icon: new Icon(Icons.skip_previous),
                    onPressed: () {
                      if (_currentPosition - 1 >= 0) {
                        Musicplayer.instance.playTracks(
                            widget.host, _tracks, _currentPosition - 1);
                      }
                    },
                    padding: EdgeInsets.all(30.0),
                    iconSize: 30.0,
                  ),
                  new IconButton(
                    icon: new Icon(_state == PlayingState.PLAYING
                        ? Icons.pause
                        : Icons.play_arrow),
                    onPressed: () {
                      if (_state == PlayingState.PLAYING) {
                        Musicplayer.instance.pause();
                      } else {
                        Musicplayer.instance.resume();
                      }
                    },
                    padding: EdgeInsets.all(30.0),
                    iconSize: 30.0,
                  ),
                  new IconButton(
                    icon: new Icon(Icons.skip_next),
                    onPressed: () {
                      if (_currentPosition + 1 < _tracks.length) {
                        Musicplayer.instance.playTracks(
                            widget.host, _tracks, _currentPosition + 1);
                      }
                    },
                    padding: EdgeInsets.all(30.0),
                    iconSize: 30.0,
                  ),
                ],
              ),
            ),
            flex: 2,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_state == null || _tracks == null || _currentPosition == null) {
      return new Scaffold(
        body: new Center(
          child: new CupertinoActivityIndicator(),
        ),
      );
    }

    MusicTrack track = _tracks[_currentPosition];

    return new Scaffold(
      appBar: new AppBar(
        backgroundColor: CupertinoColors.activeBlue,
        brightness: Brightness.dark,
        leading: new IconButton(
          icon: const BackButtonIcon(),
          onPressed: widget.onBackClick,
        ),
        title: new Text("Now playing"),
      ),
      body: new OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
          return new Column(
            children: <Widget>[
              new Expanded(
                child: orientation == Orientation.portrait
                    ? new Column(
                        children: <Widget>[
                          new Expanded(
                            child: _trackBuilder(track),
                          ),
                          new Expanded(
                            child: _buildControls(),
                          ),
                        ],
                      )
                    : new Row(
                        children: <Widget>[
                          new Expanded(
                            child: _trackBuilder(track),
                          ),
                          new Expanded(
                            child: _buildControls(),
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void onDisconnect() {
    widget.onBackClick();
  }

  @override
  void onFailure(int code, List<MusicTrack> tracks, int position) {
    if (mounted) {
      setState(() {
        _state = PlayingState.FAILED;
        _tracks = tracks;
        _currentPosition = position;
        if (_pageController != null) {
          _pageController.jumpToPage(_currentPosition);
        }
      });
    }
  }

  @override
  void onStateChanged(
      PlayingState state, List<MusicTrack> tracks, int position) {
    if (mounted) {
      setState(() {
        _state = state;
        _tracks = tracks;
        _currentPosition = position;
        if (_pageController != null) {
          _pageController.jumpToPage(_currentPosition);
        }
      });
    }
  }
}

class _Seek extends StatefulWidget {
  final Musicplayer musicplayer;
  final bool playing;

  _Seek(this.musicplayer, this.playing);

  @override
  State<StatefulWidget> createState() {
    return new _SeekState();
  }
}

class _SeekState extends State<_Seek> {
  Timer _timer;
  double _duration = 0;
  double _position = 0;
  bool onChanging = false;

  void startTimer() async {
    _timer?.cancel();

    if (mounted) {
      double duration = await widget.musicplayer.getDuration();
      double position = await widget.musicplayer.getPosition();

      setState(() {
        _duration = duration;
        _position = position;
      });

      _timer =
          Timer.periodic(new Duration(milliseconds: 500), (Timer timer) async {
        double duration = await widget.musicplayer.getDuration();
        double position = await widget.musicplayer.getPosition();

        if (mounted && !onChanging) {
          setState(() {
            _duration = duration;
            _position = position;
          });
        }
      });
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void initState() {
    super.initState();

    startTimer();

    WidgetsBinding.instance
        .addObserver(new viewUtils.LifecycleEventHandler(resumeCallBack: () {
      startTimer();
    }, suspendingCallBack: () {
      stopTimer();
    }));
  }

  @override
  void dispose() {
    super.dispose();

    stopTimer();
  }

  @override
  Widget build(BuildContext context) {
    if (_position == null ||
        _duration == null ||
        _position < 0 ||
        _position > _duration) {
      return new CupertinoActivityIndicator();
    }
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Text("${utils.fromSeconds(_position.toInt())}/"
            "${utils.fromSeconds(_duration.toInt())}"),
        new Slider(
          value: _position.toDouble(),
          onChangeStart: (double position) {
            onChanging = true;
          },
          onChanged: (double position) {
            setState(() {
              _position = position;
            });
          },
          onChangeEnd: (double position) {
            onChanging = false;
            widget.musicplayer.setPosition(position);
          },
          max: _duration.toDouble(),
          min: 0.0,
        ),
      ],
    );
  }
}
