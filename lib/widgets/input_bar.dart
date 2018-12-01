import 'package:flutter/material.dart';

class InputBar extends StatelessWidget {
  final IconData _icon;
  final Function(String text) onSubmit;
  final String hint;
  final String text;

  final TextEditingController textController = new TextEditingController();

  InputBar(this._icon, this.onSubmit, this.hint, {this.text}) {
    textController.text = text;
  }

  @override
  Widget build(BuildContext context) {
    return new Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: new Row(
        children: <Widget>[
          new Expanded(
            child: new Card(
              child: new Container(
                child: new Center(
                  child: new TextField(
                    controller: textController,
                    decoration: new InputDecoration.collapsed(
                      hintText: hint,
                      hintStyle: new TextStyle(fontSize: 18.0),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (String text) {
                      if (textController.text.isNotEmpty) {
                        onSubmit(textController.text);
                      }
                    },
                  ),
                ),
                height: 40.0,
                padding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
              margin: EdgeInsets.all(0.0),
            ),
          ),
          new Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: new FloatingActionButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  onSubmit(textController.text);
                }
              },
              mini: true,
              child: new Icon(_icon),
            ),
          ),
        ],
      ),
    );
  }
}
