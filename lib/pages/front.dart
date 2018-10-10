import 'package:flutter/material.dart';

import '../api/youtube_server.dart';
import '../view_utils.dart' as viewUtils;
import '../widgets/music.dart';
import 'parent.dart';

class FrontPage extends ParentPage<YoutubeServer> {
  FrontPage(String apiKey, String host)
      : super(apiKey, new YoutubeServer(host));

  @override
  State<StatefulWidget> createState() {
    return _FrontPageState();
  }
}

class _FrontPageState extends ParentPageState<FrontPage> {
  List<YoutubeResult> results;

  @override
  void initState() {
    super.initState();

    if (widgets.isEmpty) {
      widget.server.getCharts(new Youtube(apiKey: widget.apiKey),
          (List<YoutubeResult> results) {
        widgets = List.generate(results.length, (int index) {
          return new Music(
            results[index],
            horizontal: true,
            onClick: () {},
          );
        });
      }, (int code, Object error) {
        viewUtils.showMessageDialog(context, "Server is not reachable!");
      });
    }
  }
}
