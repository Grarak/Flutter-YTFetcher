import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LifecycleEventHandler extends WidgetsBindingObserver {
  LifecycleEventHandler({this.resumeCallBack, this.suspendingCallBack});

  final Function() resumeCallBack;
  final Function() suspendingCallBack;

  @override
  Future<Null> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.suspending:
        if (suspendingCallBack != null) {
          await suspendingCallBack();
        }
        break;
      case AppLifecycleState.resumed:
        if (resumeCallBack != null) {
          await resumeCallBack();
        }
        break;
    }
  }
}

void showMessageDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      if (Platform.isIOS) {
        return new CupertinoAlertDialog(
          title: new Text(message),
        );
      } else {
        return new AlertDialog(
          title: new Text(message),
        );
      }
    },
  );
}

void showOptionsDialog(
    BuildContext context, String message, onCancel(), onOk()) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      if (Platform.isIOS) {
        return new CupertinoAlertDialog(
          title: new Text(message),
          actions: <Widget>[
            new CupertinoDialogAction(
              child: new Text("Cancel"),
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(context, false);
                onCancel();
              },
            ),
            new CupertinoDialogAction(
              child: new Text("Ok"),
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(context, false);
                onOk();
              },
            ),
          ],
        );
      } else {
        return new AlertDialog(
          title: new Text(message),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.pop(context, false);
                onCancel();
              },
            ),
            new FlatButton(
              child: new Text("Ok"),
              onPressed: () {
                Navigator.pop(context, false);
                onOk();
              },
            )
          ],
        );
      }
    },
  );
}

void showListDialog(BuildContext context, String title, List<String> items,
    onSelected(int selection)) {
  if (Platform.isIOS) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return new CupertinoActionSheet(
          title: new Text(title),
          actions: List.generate(
            items.length,
            (int index) {
              return new CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context, false);
                  onSelected(index);
                },
                child: new Text(items[index]),
              );
            },
          ),
        );
      },
    );
  } else {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return new SimpleDialog(
          title: new Text(title),
          children: List.generate(
            items.length,
            (int index) {
              return new SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, false);
                  onSelected(index);
                },
                child: new Text(items[index]),
              );
            },
          ),
        );
      },
    );
  }
}
