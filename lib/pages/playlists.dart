import 'package:flutter/material.dart';

class PlaylistsPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PlaylistsPageState();
  }
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Text("Playlists"),
    );
  }
}
