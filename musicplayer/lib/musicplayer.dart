import 'dart:convert';

import 'package:flutter/services.dart';

class MusicTrack {
  String apiKey;
  String title;
  String id;
  String thumbnail;
  String duration;

  RegExp _titleExp = new RegExp("(.+)[:|-](.+)");

  MusicTrack(this.apiKey, this.title, this.id, this.thumbnail, this.duration);

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return new MusicTrack(
        json["apiKey"] as String,
        json["title"] as String,
        json["id"] as String,
        json["thumbnail"] as String,
        json["duration"] as String);
  }

  static List<MusicTrack> fromJsonList(List<dynamic> list) {
    List<MusicTrack> tracks = new List(list.length);
    for (int i = 0; i < list.length; i++) {
      tracks[i] = MusicTrack.fromJson(json.decode(list[i]));
    }
    return tracks;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'apiKey': apiKey,
      'title': title,
      'id': id,
      'thumbnail': thumbnail,
      'duration': duration,
    };
  }

  List<String> getFormattedTitle() {
    if (_titleExp.hasMatch(title)) {
      Match match = _titleExp.firstMatch(title);
      return [match.group(2).trim(), match.group(1).trim()];
    }

    String formattedTitle = title;
    String contentText = id;
    if (title.length > 20) {
      String tmp = title.substring(20);
      int whitespaceIndex = tmp.indexOf(' ');
      if (whitespaceIndex >= 0) {
        int firstWhitespace = 20 + whitespaceIndex;
        contentText = title.substring(firstWhitespace + 1);
        formattedTitle = title.substring(0, firstWhitespace);
      }
    }
    return [formattedTitle, contentText];
  }
}

enum PlayingState {
  PREPARING,
  PLAYING,
  PAUSED,
  FAILED,
}

abstract class MusicListener {
  void onStateChanged(
      PlayingState state, List<MusicTrack> tracks, int position);

  void onFailure(int code, List<MusicTrack> tracks, int position);

  void onDisconnect();
}

class Musicplayer {
  MethodChannel _channel = MethodChannel("musicplayer");
  Set<MusicListener> _listeners = new Set();

  Musicplayer() {
    _channel.setMethodCallHandler(_handler);
  }

  void addListener(MusicListener listener) {
    if (!hasListener(listener)) {
      _listeners.add(listener);
      _channel.invokeMethod("notify");
    }
  }

  void removeListener(MusicListener listener) {
    _listeners.remove(listener);
  }

  bool hasListener(MusicListener listener) {
    return _listeners.contains(listener);
  }

  Future<dynamic> _handler(MethodCall call) async {
    for (MusicListener listener in _listeners) {
      switch (call.method) {
        case "onPreparing":
          listener.onStateChanged(
              PlayingState.PREPARING,
              MusicTrack.fromJsonList(call.arguments["tracks"]),
              call.arguments["position"]);
          break;
        case "onFailure":
          listener.onFailure(
              call.arguments["code"],
              MusicTrack.fromJsonList(call.arguments["tracks"]),
              call.arguments["position"]);
          break;
        case "onPlay":
          listener.onStateChanged(
              PlayingState.PLAYING,
              MusicTrack.fromJsonList(call.arguments["tracks"]),
              call.arguments["position"]);
          break;
        case "onPause":
          listener.onStateChanged(
              PlayingState.PAUSED,
              MusicTrack.fromJsonList(call.arguments["tracks"]),
              call.arguments["position"]);
          break;
        case "onDisconnect":
          listener.onDisconnect();
          break;
        default:
          return call.noSuchMethod(null);
      }
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

  Future<dynamic> resume() {
    return _channel.invokeMethod("resume");
  }

  Future<dynamic> pause() {
    return _channel.invokeMethod("pause");
  }

  Future<int> getDuration() async {
    return await _channel.invokeMethod("getDuration");
  }

  Future<int> getPosition() async {
    return await _channel.invokeMethod("getPosition");
  }

  Future<dynamic> setPosition(int position) async {
    return _channel
        .invokeMethod("setPosition", <String, dynamic>{"position": position});
  }

  Future<MusicTrack> getCurrentTrack() async {
    Map<dynamic, dynamic> args = await _channel.invokeMethod("getCurrentTrack");
    if (args == null) {
      return null;
    }
    Map<String, dynamic> json = new Map();
    args.forEach((dynamic key, dynamic value) {
      json[key] = value;
    });
    return MusicTrack.fromJson(json);
  }

  Future<dynamic> unbind() async {
    return _channel.invokeMethod("unbind");
  }
}
