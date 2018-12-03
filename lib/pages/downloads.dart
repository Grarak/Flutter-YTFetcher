import 'package:flutter/material.dart';
import 'package:musicplayer/musicplayer.dart';

import 'parent.dart';
import '../download_manager.dart';
import '../widgets/download_item.dart';
import '../view_utils.dart' as viewUtils;

class DownloadsPage extends ParentPage {
  DownloadsPage(String apiKey, String host, {Key key})
      : super(apiKey, host, key: key);

  @override
  State<StatefulWidget> createState() {
    return new _DownloadsPageState();
  }
}

class _DownloadsPageState extends ParentPageState<DownloadsPage>
    implements DownloadManagerListener {
  bool initialized = false;

  @override
  void initState() {
    super.initState();

    gridAxisCount = 1;
    initDownloads();
  }

  @override
  void onDownloadCompleted(Download download) {
    initDownloads();
  }

  @override
  void onDownloadDeleted(Download download) {
    initDownloads();
  }

  @override
  Widget buildLoadingWidget() {
    return initialized
        ? new Text(
            "No downloads",
            style: new TextStyle(fontSize: 18.0),
          )
        : super.buildLoadingWidget();
  }

  void initDownloads() async {
    DownloadManager.instance.then((DownloadManager manager) {
      initialized = true;

      manager.listener = this;
      widgets = List.generate(manager.downloads.length, (int index) {
        Download download = manager.downloads[index];
        return new DownloadItem(
          download,
          () async {
            await Musicplayer.instance.playTrack(widget.youtubeServer.host,
                download.youtubeResult.toTrack(widget.apiKey));
          },
          () async {
            MusicTrack currentTrack =
                await Musicplayer.instance.getCurrentTrack();
            if (currentTrack != null &&
                currentTrack.id == download.youtubeResult.id) {
              viewUtils.showMessageDialog(
                  context, "Can't delete file when it's playing");
            } else {
              viewUtils.showOptionsDialog(
                  context,
                  "Do you really want to delete ${download.youtubeResult.title}?",
                  null, () {
                download.delete();
              });
            }
          },
        );
      });
    });
  }
}
