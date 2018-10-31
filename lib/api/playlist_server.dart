import 'dart:convert';
import 'dart:async';

import 'package:json_annotation/json_annotation.dart';

import 'server.dart';
import '../utils.dart';

part 'playlist_server.g.dart';

@JsonSerializable(includeIfNull: false)
class Playlist {
  String apikey;
  String name;
  bool public;

  Playlist({this.apikey, this.name, this.public});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return _$PlaylistFromJson(json);
  }

  @override
  String toString() {
    return json.encode(_$PlaylistToJson(this));
  }
}

class PlaylistServer extends Server {
  PlaylistServer(String host) : super(host);

  void list(String apiKey, onSuccess(List<Playlist> playlists),
      onError(int code, Object error)) {
    post("users/playlist/list", "{\"apikey\":\"$apiKey\"}",
        (String response) async {
      onSuccess(await _parseList(response));
    }, (int code, Object error) async {
      List<Playlist> list = await _parseList(null);
      if (list == null) {
        onError(code, error);
      } else {
        onSuccess(list);
      }
    });
  }

  Future<List<Playlist>> _parseList(String response) async {
    if (response != null) {
      List<Playlist> results = new List();

      List<dynamic> unparsedJson = json.decode(response);
      Settings.saveString("playlists", response);

      for (dynamic result in unparsedJson) {
        results.add(Playlist.fromJson(result));
      }
      return results;
    }

    String cached = await Settings.getString("playlists", null);
    if (cached != null) {
      return _parseList(cached);
    }

    return null;
  }

  void listIds(Playlist playlist, onSuccess(List<String> ids),
      onError(int code, Object error)) {
    post("users/playlist/listids", playlist.toString(),
        (String response) async {
      onSuccess(await _parseListIds(playlist.name, response));
    }, (int code, Object error) async {
      List<String> list = await _parseListIds(playlist.name, null);
      if (list == null) {
        onError(code, error);
      } else {
        onSuccess(list);
      }
    });
  }

  Future<List<String>> _parseListIds(String name, String response) async {
    if (response != null) {
      Settings.saveString("${name}_ids", response);
      List<String> results = new List();
      for (dynamic result in json.decode(response)) {
        results.add(result);
      }
      return results;
    }

    String cached = await Settings.getString("${name}_ids", null);
    if (cached != null) {
      return _parseListIds(name, cached);
    }
    return null;
  }
}
