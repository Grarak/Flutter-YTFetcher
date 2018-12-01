import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SettingsPage extends StatelessWidget {
  final Function(BuildContext context) onSignOut;

  SettingsPage(this.onSignOut, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Center(
      child: new CupertinoButton(
        child: new Text("Sign out"),
        color: Colors.red,
        onPressed: () {
          onSignOut(context);
        },
      ),
    );
  }
}
