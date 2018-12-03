import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'utils.dart' as utils;
import 'api/youtube_server.dart';
import 'view_utils.dart' as viewUtils;

abstract class DownloadListener {
  void onDownloadComplete(Download download);

  void onDownloadDelete(Download download);
}

class Download {
  final Directory _root;
  YoutubeServer server;
  final YoutubeResult youtubeResult;
  final List<DownloadListener> _listeners = new List();
  IOSink _sink;
  HttpClient _client;

  Download(this._root, this.youtubeResult);

  File get _file => new File("${_root.path}/$_fileName");

  File get _downloadFile => new File("${_root.path}/$_fileName.tmp");

  String get _fileName => "${youtubeResult.id}.ogg";

  void addListener(DownloadListener listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(DownloadListener listener) {
    _listeners.remove(listener);
  }

  void _startDownloadDelayed() {
    new Future.delayed(new Duration(seconds: 10), () {
      _startDownload();
    });
  }

  void _startDownload() async {
    if (isDownloaded()) {
      return;
    }

    String api = await utils.Settings.getApiKey();
    if (api == null) {
      return;
    }

    String host = await utils.Settings.getHost();
    if (host == null) {
      return;
    }

    if (!_downloadFile.existsSync()) {
      _downloadFile.createSync();
    }

    server?.close();
    server = new YoutubeServer(host);
    server.fetchSong(
      new Youtube(apikey: api, id: youtubeResult.id),
      (String url) async {
        if (url.startsWith(host)) {
          _client = new HttpClient();
          HttpClientRequest request;
          try {
            request = await _client.getUrl(Uri.parse(url));
          } on SocketException catch (_) {
            _startDownloadDelayed();
            return;
          }

          File file = _downloadFile;
          request.close().then((HttpClientResponse response) {
            _sink = file.openWrite(mode: FileMode.writeOnly);
            response.pipe(_sink).whenComplete(() {
              _client.close(force: true);
              file.renameSync(_file.path);
              for (DownloadListener listener in _listeners) {
                listener.onDownloadComplete(this);
              }
            }).catchError(() {
              _client.close(force: true);
              _startDownloadDelayed();
            });
          });
        } else {
          _startDownloadDelayed();
        }
      },
      (int status, Object error) {
        _startDownloadDelayed();
      },
    );
  }

  bool isDownloaded() {
    return _file.existsSync();
  }

  void delete() async {
    _client?.close(force: true);
    try {
      await _sink?.flush();
    } on Error catch (_) {}
    try {
      await _sink?.close();
    } on Error catch (_) {}
    if (_file.existsSync()) {
      _file.deleteSync();
    }
    if (_downloadFile.existsSync()) {
      _downloadFile.deleteSync();
    }

    for (DownloadListener listener in _listeners) {
      listener.onDownloadDelete(this);
    }
  }

  @override
  int get hashCode => youtubeResult.id.hashCode;

  @override
  bool operator ==(Object other) {
    return other is Download && youtubeResult.id == other.youtubeResult.id;
  }
}

abstract class DownloadManagerListener {
  void onDownloadCompleted(Download download);

  void onDownloadDeleted(Download download);
}

class DownloadManager implements DownloadListener {
  final Directory _root;
  final List<Download> downloads;
  DownloadManagerListener listener;

  DownloadManager(this._root, this.downloads);

  void queue(BuildContext context, YoutubeResult result) {
    if (int.parse(result.duration.split(":")[0]) > 20) {
      viewUtils.showMessageDialog(context, "Too long to be downloaded");
    } else {
      Download download = _createDownload(result);
      if (!downloads.contains(download)) {
        YoutubeServer.saveResult(result);
        if (download.isDownloaded()) {
          download._file.deleteSync();
        }
        downloads.add(download);
        download._startDownload();
        downloads.sort((Download a, Download b) {
          return a.youtubeResult.title
              .toLowerCase()
              .compareTo(b.youtubeResult.title.toLowerCase());
        });
      } else if (context != null) {
        viewUtils.showMessageDialog(context, "Already downloaded");
      }
    }
  }

  Download _createDownload(YoutubeResult result) {
    Download download = new Download(_root, result);
    download.addListener(this);
    return download;
  }

  static DownloadManager _instance;

  static Future<DownloadManager> get instance async {
    if (_instance == null) {
      _instance = await _createInstance();
    }
    return _instance;
  }

  static Future<DownloadManager> _createInstance() async {
    Directory root = await getApplicationDocumentsDirectory();
    root.createSync();
    List<Download> downloads = new List();
    DownloadManager downloadManager = new DownloadManager(root, downloads);

    List<FileSystemEntity> files = root.listSync();
    for (FileSystemEntity entity in files) {
      if (entity is File) {
        String fileName = path.basename(entity.path);
        String id = path.basenameWithoutExtension(fileName);
        if (id.endsWith(".ogg")) {
          id = path.basenameWithoutExtension(id);
        }
        YoutubeResult result = await YoutubeServer.parseInfo(id, null);
        if (result != null) {
          Download download = downloadManager._createDownload(result);
          download._startDownload();
          downloads.add(download);
        }
      }
    }

    downloads.sort((Download a, Download b) {
      return a.youtubeResult.title
          .toLowerCase()
          .compareTo(b.youtubeResult.title.toLowerCase());
    });
    return downloadManager;
  }

  @override
  void onDownloadComplete(Download download) {
    listener?.onDownloadCompleted(download);
  }

  @override
  void onDownloadDelete(Download download) {
    downloads.remove(download);
    listener?.onDownloadDeleted(download);
  }
}
