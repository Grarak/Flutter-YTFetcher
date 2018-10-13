import 'package:flutter/services.dart';

class MusicTrack {
  String apiKey;
  String title;
  String id;
  String thumbnail;
  String duration;

  MusicTrack(this.apiKey, this.title, this.id, this.thumbnail, this.duration);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'apiKey': apiKey,
      'title': title,
      'id': id,
      'thumbnail': thumbnail,
      'duration': duration,
    };
  }
}

abstract class MusicListener {
  void onPreparing(List<MusicTrack> tracks, int position);

  void onFailure(int code, List<MusicTrack> tracks, int position);

  void onPlay(List<MusicTrack> tracks, int position);

  void onPause(List<MusicTrack> tracks, int position);

  void onDisconnect();
}

class Musicplayer {
  final MethodChannel _channel = MethodChannel("musicplayer");
  final Set<MusicListener> _listeners = new Set();

  Musicplayer() {
    _channel.setMethodCallHandler(_handler);
  }

  void addListener(MusicListener listener) {
    _listeners.add(listener);
    print(_listeners.length);
  }

  Future<dynamic> _handler(MethodCall call) async {
    switch (call.method) {
      case "onPreparing":
        break;
      case "onFailure":
        break;
      case "onPlay":
        break;
      case "onPause":
        break;
      default:
        call.noSuchMethod(null);
        break;
    }
  }

  Future<dynamic> playTrack(String url, MusicTrack track) async {
    return playTracks(url, <MusicTrack>[track], 0);
  }

  Future<dynamic> playTracks(
      String url, List<MusicTrack> tracks, int position) async {
    List<dynamic> jsonTracks = new List(tracks.length);
    for (int i = 0; i < tracks.length; i++) {
      jsonTracks[i] = tracks[i].toJson();
    }
    return _channel.invokeMethod("playTracks", <String, dynamic>{
      "url": url,
      "tracks": jsonTracks,
      "position": position
    });
  }

  Future<dynamic> unbind() async {
    return _channel.invokeMethod("unbind");
  }
}
