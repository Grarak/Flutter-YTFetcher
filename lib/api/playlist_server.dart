import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import 'server.dart';
import '../utils.dart' as utils;

part 'playlist_server.g.dart';

@JsonSerializable(includeIfNull: false)
class Playlist {
  String apikey;
  String name;
  bool public;

  Playlist({this.apikey, this.name, this.public});

  factory Playlist.fromJson(Map<String, dynamic> json) {
    Playlist playlist = _$PlaylistFromJson(json);
    playlist.name = utils.decodeUTF8(playlist.name);
    return playlist;
  }

  Map<String, dynamic> toJson() {
    return _$PlaylistToJson(this);
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}

@JsonSerializable(includeIfNull: false)
class PlaylistId {
  String apikey;
  String name;
  String id;

  PlaylistId({this.apikey, this.name, this.id});

  factory PlaylistId.fromJson(Map<String, dynamic> json) {
    return _$PlaylistIdFromJson(json);
  }

  @override
  String toString() {
    return json.encode(_$PlaylistIdToJson(this));
  }
}

class PlaylistServer extends Server {
  PlaylistServer(String host) : super(host);

  void list(String apiKey, onSuccess(List<Playlist> playlists),
      onError(int code, Object error)) {
    post("users/playlist/list", "{\"apikey\":\"$apiKey\"}",
        (HttpHeaders headers, String response) async {
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
      utils.Settings.saveString("playlists", response);

      for (dynamic result in unparsedJson) {
        results.add(Playlist.fromJson(result));
      }
      return results;
    }

    String cached = await utils.Settings.getString("playlists", null);
    if (cached != null) {
      return _parseList(cached);
    }

    return null;
  }

  void create(Playlist playlist, onSuccess(), onError(int code, Object error)) {
    post("users/playlist/create", playlist.toString(),
        (HttpHeaders headers, String response) {
      onSuccess();
    }, onError);
  }

  void delete(Playlist playlist, onSuccess(), onError(int code, Object error)) {
    post("users/playlist/delete", playlist.toString(),
        (HttpHeaders headers, String response) {
      onSuccess();
    }, onError);
  }

  void addId(
      PlaylistId playlistId, onSuccess(), onError(int code, Object error)) {
    post("users/playlist/addid", playlistId.toString(),
        (HttpHeaders headers, String response) {
      onSuccess();
    }, onError);
  }

  void listIds(Playlist playlist, onSuccess(List<String> ids),
      onError(int code, Object error)) {
    post("users/playlist/listids", playlist.toString(),
        (HttpHeaders headers, String response) async {
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
      utils.Settings.saveString("${name}_ids", response);
      List<String> results = new List();
      for (dynamic result in json.decode(response)) {
        results.add(result);
      }
      return results;
    }

    String cached = await utils.Settings.getString("${name}_ids", null);
    if (cached != null) {
      return _parseListIds(name, cached);
    }
    return null;
  }

  void deleteId(
      PlaylistId playlistId, onSuccess(), onError(int code, Object error)) {
    post("users/playlist/deleteid", playlistId.toString(),
        (HttpHeaders headers, String response) {
      onSuccess();
    }, onError);
  }

  void setIds(Playlist playlist, List<String> ids, onSuccess(),
      onError(int code, Object error)) {
    Map<String, dynamic> data = playlist.toJson();
    data["ids"] = ids;
    data.remove("public");
    post("users/playlist/setids", json.encode(data),
        (HttpHeaders headers, String response) {
      onSuccess();
    }, onError);
  }
}
