import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

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
