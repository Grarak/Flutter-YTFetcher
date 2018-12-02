import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class SettingsPage extends StatelessWidget {
  final Function(BuildContext context) onHistory;
  final Function(BuildContext context) onSignOut;

  SettingsPage(this.onHistory, this.onSignOut, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var dividedWidgetList = ListTile.divideTiles(
      context: context,
      tiles: [
        new _SettingsItem(
          "History",
          () {
            onHistory(context);
          },
        ),
        new _SettingsItem(
          "Licenses",
          () {
            Navigator.push(
                context,
                new CupertinoPageRoute(
                    builder: (BuildContext context) => new LicensePage()));
          },
        ),
        new _SettingsItem(
          "Sign out",
          () {
            onSignOut(context);
          },
        ),
      ],
    ).toList();

    return new ListView(
      children: dividedWidgetList,
      physics: BouncingScrollPhysics(),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final String text;
  final Function() onClick;

  _SettingsItem(this.text, this.onClick);

  @override
  Widget build(BuildContext context) {
    return new InkWell(
      child: new Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: new Text(
          text,
          style: new TextStyle(fontSize: 17.0),
        ),
      ),
      onTap: () {
        onClick();
      },
    );
  }
}
