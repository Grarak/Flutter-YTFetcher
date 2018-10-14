import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:musicplayer/musicplayer.dart';

class MusicBar extends StatelessWidget {
  final MusicTrack _track;
  final PlayingState _state;
  final Function() onResume;
  final Function() onPause;
  final Function() onClick;

  MusicBar(this._track, this._state, this.onResume, this.onPause, this.onClick,
      {Key key})
      : super(key: key);

  Widget _empty() {
    return new Center(
      child: new Text("No music"),
    );
  }

  Widget _leftWidget() {
    switch (_state) {
      case PlayingState.PLAYING:
        return new Icon(Icons.pause);
      case PlayingState.PAUSED:
        return new Icon(Icons.play_arrow);
      case PlayingState.PREPARING:
      default:
        return new CircularProgressIndicator();
    }
  }

  Widget _music() {
    return new Row(
      children: <Widget>[
        new Expanded(
          child: new InkWell(
            child: new Center(
              child: _leftWidget(),
            ),
            onTap: () {
              if (_state == PlayingState.PLAYING) {
                if (onPause != null) {
                  onPause();
                }
              } else if (_state == PlayingState.PAUSED) {
                if (onResume != null) {
                  onResume();
                }
              }
            },
          ),
          flex: 1,
        ),
        new Expanded(
          child: new SizedBox.expand(
            child: new InkWell(
              child: new Center(
                child: new Text(
                  _track.getFormattedTitle(),
                  textAlign: TextAlign.center,
                ),
              ),
              onTap: onClick,
            ),
          ),
          flex: 3,
        ),
        new Expanded(
          child: new SizedBox.expand(
            child: new CachedNetworkImage(
              imageUrl: _track.thumbnail,
              fit: BoxFit.fitHeight,
            ),
          ),
          flex: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      elevation: 10.0,
      child: new Container(
        decoration: BoxDecoration(),
        height: 60.0,
        child: _track == null ? _empty() : _music(),
      ),
    );
  }
}
