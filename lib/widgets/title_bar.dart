import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class TitleBar extends StatelessWidget {
  final String title;
  final Widget rightSide;
  final Function() onBackClick;

  TitleBar(
      {@required this.title,
      @required this.rightSide,
      @required this.onBackClick});

  List<Widget> _buildItems() {
    List<Widget> widgets = new List();
    widgets.add(
      new IconButton(
        icon: new Icon(Icons.arrow_back_ios),
        onPressed: () {
          if (onBackClick != null) {
            onBackClick();
          }
        },
        color: CupertinoColors.activeBlue,
      ),
    );
    widgets.add(
      new Expanded(
        child: new Text(
          title.toUpperCase(),
          style: new TextStyle(fontSize: 16.0),
        ),
      ),
    );
    if (rightSide != null) {
      widgets.add(rightSide);
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      elevation: 5.0,
      child: new Padding(
        padding: EdgeInsets.only(top: 8.0, bottom: 8.0, right: 16.0),
        child: new SafeArea(
          bottom: false,
          child: new Row(
            children: _buildItems(),
          ),
        ),
      ),
    );
  }
}
