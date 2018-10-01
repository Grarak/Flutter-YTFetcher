import 'package:flutter/material.dart';

import 'view_utils.dart';

void main() => runApp(new Login());

class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: new LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({Key key}) : super(key: key);

  @override
  _LoginPageState createState() => new _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController serverAddressController =
      new TextEditingController();
  final TextEditingController usernameController = new TextEditingController();
  final TextEditingController passwordController = new TextEditingController();
  final TextEditingController confirmPasswordController =
      new TextEditingController();

  final FocusNode serverAddressFocus = new FocusNode();
  final FocusNode usernameFocus = new FocusNode();
  final FocusNode passwordFocus = new FocusNode();
  final confirmPasswordFocus = new FocusNode();

  bool signUp = true;

  void onSwitchButtonPressed() {
    setState(() {
      signUp = !signUp;
    });
  }

  void onSubmit() {
    if (serverAddressController.text.isEmpty) {
      showMessageDialog(context, "Server address can't be empty");
      return;
    } else if (!serverAddressController.text.startsWith("http")) {
      serverAddressController.text = "http://${serverAddressController.text}";
    }

    if (usernameController.text.length <= 3) {
      showMessageDialog(context, "Username must be at least 4 characters long");
      return;
    } else if (!new RegExp("^[a-zA-Z0-9_]*\$")
        .hasMatch(usernameController.text)) {
      showMessageDialog(
          context, "Username should only contain alphanumeric characters");
      return;
    }

    if (passwordController.text.length <= 4) {
      showMessageDialog(context, "Password must be at least 4 characters long");
      return;
    }

    if (signUp && passwordController.text != confirmPasswordController.text) {
      showMessageDialog(context, "Passwords do not match");
      return;
    }


  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Padding(
        padding: EdgeInsets.all(16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Expanded(
              child: new Card(
                child: new Padding(
                    padding: EdgeInsets.all(16.0),
                    child: new Stack(
                      children: <Widget>[
                        new Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            new _Input(
                                "Server address",
                                serverAddressController,
                                serverAddressFocus, (String text) {
                              FocusScope.of(context)
                                  .requestFocus(usernameFocus);
                            }),
                            new _Input(
                                "Username", usernameController, usernameFocus,
                                (String text) {
                              FocusScope.of(context)
                                  .requestFocus(passwordFocus);
                            }),
                            new _Input(
                              "Password",
                              passwordController,
                              passwordFocus,
                              (String text) {
                                if (signUp) {
                                  FocusScope.of(context)
                                      .requestFocus(confirmPasswordFocus);
                                } else {
                                  onSubmit();
                                }
                              },
                              secure: true,
                              action: signUp
                                  ? TextInputAction.next
                                  : TextInputAction.done,
                            ),
                            signUp
                                ? new _Input(
                                    "Confirm password",
                                    confirmPasswordController,
                                    confirmPasswordFocus,
                                    (String text) {
                                      onSubmit();
                                    },
                                    secure: true,
                                    action: TextInputAction.done,
                                  )
                                : new Container(),
                          ],
                        ),
                        new Align(
                          alignment: Alignment(1.0, 1.0),
                          child: new FloatingActionButton(
                            onPressed: onSubmit,
                            child: new Icon(Icons.done),
                          ),
                        )
                      ],
                    )),
              ),
              flex: 3,
            ),
            new Expanded(
              child: new Center(
                child: new RaisedButton(
                  onPressed: onSwitchButtonPressed,
                  child: new Text(
                      signUp ? "Switch to login" : "Switch to sign up"),
                ),
              ),
              flex: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String name;
  final bool secure;
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String text) onSubmitted;
  final TextInputAction action;

  const _Input(this.name, this.controller, this.focusNode, this.onSubmitted,
      {this.secure, this.action});

  @override
  Widget build(BuildContext context) {
    return new TextField(
      decoration: new InputDecoration(labelText: name),
      textInputAction: action == null ? TextInputAction.next : action,
      controller: controller,
      obscureText: secure != null && secure,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
    );
  }
}
