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
            content: new Text(message),
          );
        } else {
          return new AlertDialog(
            content: new Text(message),
          );
        }
      });
}
