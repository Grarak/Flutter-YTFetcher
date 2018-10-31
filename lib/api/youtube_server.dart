import 'dart:convert';
import 'dart:async';

import 'package:json_annotation/json_annotation.dart';
import 'package:musicplayer/musicplayer.dart';

import 'server.dart';
import '../utils.dart';

part 'youtube_server.g.dart';

@JsonSerializable(includeIfNull: false)
class Youtube {
  String apikey;
  String searchquery;
  String id;
  bool addhistory;

  Youtube({this.apikey, this.searchquery, this.id, this.addhistory});

  factory Youtube.fromJson(String data) => _$YoutubeFromJson(json.decode(data));

  @override
  String toString() {
    return json.encode(_$YoutubeToJson(this));
  }
}

@JsonSerializable(includeIfNull: false)
class YoutubeResult {
  String title;
  String id;
  String thumbnail;
  String duration;

  YoutubeResult({this.title, this.id, this.thumbnail, this.duration});

  factory YoutubeResult.fromString(String data) =>
      _$YoutubeResultFromJson(json.decode(data));

  factory YoutubeResult.fromJson(Map<String, dynamic> j) =>
      _$YoutubeResultFromJson(j);

  @override
  String toString() {
    return json.encode(_$YoutubeResultToJson(this));
  }

  MusicTrack toTrack(String apiKey) {
    return new MusicTrack(apiKey, title, id, thumbnail, duration);
  }
}

class YoutubeServer extends Server {
  YoutubeServer(String host) : super(host);

  void getCharts(Youtube youtube, onSuccess(List<YoutubeResult> results),
      onError(int code, Object error)) {
    post("youtube/getcharts", youtube.toString(), (String response) async {
      onSuccess(await _parseCharts(response));
    }, (int code, Object error) async {
      List<YoutubeResult> results = await _parseCharts(null);
      if (results == null) {
        onError(code, error);
      } else {
        onSuccess(results);
      }
    });
  }

  Future<List<YoutubeResult>> _parseCharts(String response) async {
    if (response != null) {
      List<YoutubeResult> results = new List();

      List<dynamic> unparsedResults = json.decode(response);
      Settings.saveString("charts", response);

      for (dynamic result in unparsedResults) {
        results.add(YoutubeResult.fromJson(result));
      }

      return results;
    }

    String cached = await Settings.getString("charts", null);
    if (cached != null) {
      return _parseCharts(cached);
    }
    return null;
  }

  void getInfo(Youtube youtube, onSuccess(YoutubeResult result),
      onError(int code, Object error)) async {
    YoutubeResult result = await _parseInfo(youtube.id, null);
    if (result != null) {
      onSuccess(result);
      return;
    }
    post("youtube/getinfo", youtube.toString(), (String response) async {
      onSuccess(await _parseInfo(youtube.id, response));
    }, (int code, Object error) async {
      YoutubeResult result = await _parseInfo(youtube.id, null);
      if (result == null) {
        onError(code, error);
      } else {
        onSuccess(result);
      }
    });
  }

  Future<YoutubeResult> _parseInfo(String id, String response) async {
    if (response != null) {
      Settings.saveString("resultId_$id", response);
      return YoutubeResult.fromString(response);
    }

    String cached = await Settings.getString("resultId_$id", null);
    if (cached != null) {
      return _parseInfo(id, cached);
    }
    return null;
  }

  void getInfoList(List<Youtube> youtubes,
      onSuccess(List<YoutubeResult> results), onError(int code, Object error)) {
    Map<String, YoutubeResult> mappedResults = new Map();
    for (Youtube youtube in youtubes) {
      getInfo(youtube, (YoutubeResult result) {
        mappedResults[result.id] = result;
        if (mappedResults.length == youtubes.length) {
          List<YoutubeResult> results = new List();
          for (Youtube youtube in youtubes) {
            results.add(mappedResults[youtube.id]);
          }
          onSuccess(results);
        }
      }, (int code, Object error) {
        close();
        onError(code, error);
      });
    }
  }

  void search(Youtube youtube, onSuccess(List<YoutubeResult> results),
      onError(int code, Object error)) {
    post("youtube/search", youtube.toString(), (String response) {
      List<YoutubeResult> results = new List();
      List<dynamic> unparsedResults = json.decode(response);
      for (dynamic result in unparsedResults) {
        results.add(YoutubeResult.fromJson(result));
      }
      onSuccess(results);
    }, onError);
  }
}
