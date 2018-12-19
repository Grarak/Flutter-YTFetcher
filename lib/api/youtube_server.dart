import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:musicplayer/musicplayer.dart';

import 'server.dart';
import '../utils.dart' as utils;

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
      YoutubeResult.fromJson(json.decode(data));

  factory YoutubeResult.fromJson(Map<String, dynamic> j) {
    YoutubeResult youtubeResult = _$YoutubeResultFromJson(j);
    youtubeResult.title = utils.decodeUTF8(youtubeResult.title);
    return youtubeResult;
  }

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

  void getCharts(
    Youtube youtube,
    onSuccess(List<YoutubeResult> results),
    onError(int code, Object error),
  ) {
    post(
      "youtube/getcharts",
      youtube.toString(),
      (HttpHeaders headers, String response) async {
        onSuccess(await _parseCharts(response));
      },
      (int code, Object error) async {
        List<YoutubeResult> results = await _parseCharts(null);
        if (results == null) {
          onError(code, error);
        } else {
          onSuccess(results);
        }
      },
    );
  }

  Future<List<YoutubeResult>> _parseCharts(String response) async {
    if (response != null) {
      List<YoutubeResult> results = new List();

      List<dynamic> unparsedResults = json.decode(response);
      utils.Settings.saveString("charts", response);

      for (dynamic result in unparsedResults) {
        results.add(YoutubeResult.fromJson(result));
      }

      return results;
    }

    String cached = await utils.Settings.getString("charts", null);
    if (cached != null) {
      return _parseCharts(cached);
    }
    return null;
  }

  void getInfo(
    Youtube youtube,
    onSuccess(YoutubeResult result),
    onError(int code, Object error),
  ) async {
    YoutubeResult result = await parseInfo(youtube.id, null);
    if (result != null) {
      onSuccess(result);
      return;
    }
    post(
      "youtube/getinfo",
      youtube.toString(),
      (HttpHeaders headers, String response) async {
        onSuccess(await parseInfo(youtube.id, response));
      },
      (int code, Object error) async {
        YoutubeResult result = await parseInfo(youtube.id, null);
        if (result == null) {
          onError(code, error);
        } else {
          onSuccess(result);
        }
      },
    );
  }

  static void saveResult(YoutubeResult result) {
    utils.Settings.saveString("resultId_${result.id}", result.toString());
  }

  static Future<YoutubeResult> parseInfo(String id, String response) async {
    if (response != null) {
      utils.Settings.saveString("resultId_$id", response);
      return YoutubeResult.fromString(response);
    }

    String cached = await utils.Settings.getString("resultId_$id", null);
    if (cached != null) {
      return parseInfo(id, cached);
    }
    return null;
  }

  void getInfoList(
      List<Youtube> youtubes,
      onSuccess(List<YoutubeResult> results),
      onError(int code, Object error),
      onProgress(int progress)) {
    Map<String, YoutubeResult> mappedResults = new Map();

    Function(int start) fetch;
    Function(int count) callback = (int count) {
      if (mappedResults.length == youtubes.length) {
        List<YoutubeResult> results = new List();
        for (Youtube youtube in youtubes) {
          YoutubeResult result = mappedResults[youtube.id];
          if (result != null) {
            results.add(result);
          }
        }
        onSuccess(results);
      } else if (mappedResults.length == count) {
        fetch(count);
      }
    };

    fetch = (int start) {
      for (int i = start; i < start + 10 && i < youtubes.length; i++) {
        getInfo(youtubes[i], (YoutubeResult result) {
          mappedResults[youtubes[i].id] = result;
          onProgress(mappedResults.length);
          callback(start + 10);
        }, (int status, Object error) {
          mappedResults[youtubes[i].id] = null;
          onProgress(mappedResults.length);
          callback(start + 10);
        });
      }
    };

    fetch(0);
  }

  void search(
    Youtube youtube,
    onSuccess(List<YoutubeResult> results),
    onError(int code, Object error),
  ) {
    post(
      "youtube/search",
      youtube.toString(),
      (HttpHeaders headers, String response) {
        List<YoutubeResult> results = new List();
        List<dynamic> unparsedResults = json.decode(response);
        for (dynamic result in unparsedResults) {
          results.add(YoutubeResult.fromJson(result));
        }
        onSuccess(results);
      },
      onError,
    );
  }

  void fetchSong(
    Youtube youtube,
    onSuccess(String url),
    onError(int code, Object error),
  ) {
    post(
      "youtube/fetch",
      youtube.toString(),
      (HttpHeaders headers, String response) {
        String id = headers.value("ytfetcher-id");
        if (id == null) {
          onSuccess(response);
        } else {
          _verifyFetchedSong(response, id, onSuccess, onError);
        }
      },
      onError,
    );
  }

  void _verifyFetchedSong(
    String url,
    String id,
    onSuccess(String url),
    onError(int code, Object error),
  ) {
    getUri(
      Uri.parse(url),
      (HttpHeaders headers, String response) {},
      (int code, Object error) {
        _verifyForwardedSong(url, id, onSuccess, onError);
      },
      onConnect: (int status, Uri uri) {
        if (status == HttpStatus.ok) {
          onSuccess(uri.toString());
        } else {
          _verifyForwardedSong(uri.toString(), id, onSuccess, onError);
        }
        return false;
      },
    );
  }

  void _verifyForwardedSong(
    String url,
    String id,
    onSuccess(String response),
    onError(int code, Object error),
  ) {
    Uri uri = buildUri("youtube/get").replace(
      queryParameters: {
        "id": id,
        "url": url,
      },
    );
    getUri(
      uri,
      (HttpHeaders headers, String response) {},
      onError,
      onConnect: (int status, Uri uri) {
        if (status == HttpStatus.ok) {
          onSuccess(uri.toString());
        } else {
          onError(status, null);
        }
        return false;
      },
    );
  }
}
