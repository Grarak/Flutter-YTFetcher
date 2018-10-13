import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:musicplayer/musicplayer.dart';

import 'server.dart';

part 'youtube_server.g.dart';

@JsonSerializable(includeIfNull: false)
class Youtube {
  String apiKey;
  String searchquery;
  String id;
  bool addhistory;

  Youtube({this.apiKey, this.searchquery, this.id, this.addhistory});

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

  YoutubeResult(this.title, this.id, this.thumbnail, this.duration);

  factory YoutubeResult.fromJson(String data) =>
      _$YoutubeResultFromJson(json.decode(data));

  factory YoutubeResult.parse(dynamic j) => _$YoutubeResultFromJson(j);

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
    post("youtube/getcharts", youtube.toString(), (String response) {
      List<YoutubeResult> results = new List();
      List<dynamic> parsedResults = json.decode(response);
      for (dynamic result in parsedResults) {
        results.add(YoutubeResult.parse(result));
      }
      onSuccess(results);
    }, onError);
  }
}
