import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'api/user_server.dart';
import 'api/codes.dart' as codes;
import 'utils.dart' as utils;
import 'view_utils.dart' as viewUtils;
import 'home.dart';

void main() async {
  String apiKey = await utils.Settings.getApiKey();
  String host = await utils.Settings.getHost();
  if (apiKey != null && host != null) {
    runApp(new Home(apiKey, host));
  } else {
    runApp(new Login());
  }
}

class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'YTFetcher',
      theme: new ThemeData(
        accentColor: CupertinoColors.activeBlue,
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

  bool loading = false;

  void onSwitchButtonPressed() {
    setState(() {
      signUp = !signUp;
    });
  }

  void onSubmit() async {
    if (serverAddressController.text.isEmpty) {
      viewUtils.showMessageDialog(context, "Server address can't be empty");
      return;
    } else if (!serverAddressController.text.startsWith("http")) {
      serverAddressController.text = "https://${serverAddressController.text}";
    }

    if (usernameController.text.length <= 3) {
      viewUtils.showMessageDialog(
          context, "Username must be at least 4 characters long");
      return;
    } else if (!new RegExp("^[a-zA-Z0-9_]*\$")
        .hasMatch(usernameController.text)) {
      viewUtils.showMessageDialog(
          context, "Username should only contain alphanumeric characters");
      return;
    }

    if (passwordController.text.length <= 4) {
      viewUtils.showMessageDialog(
          context, "Password must be at least 4 characters long");
      return;
    }

    if (signUp && passwordController.text != confirmPasswordController.text) {
      viewUtils.showMessageDialog(context, "Passwords do not match");
      return;
    }

    UserServer userServer = new UserServer(serverAddressController.text);
    User user = new User(
        name: usernameController.text,
        password: utils.toBase64(passwordController.text));

    Function(User user) onSuccess = (User user) {
      setState(() {
        loading = false;
      });

      if (user.verified) {
        utils.Settings.setApiKey(user.apikey);
        utils.Settings.setHost(serverAddressController.text);
        Navigator.pushReplacement(context,
            new CupertinoPageRoute(builder: (BuildContext context) {
          return new Home(user.apikey, serverAddressController.text);
        }));
      } else {
        viewUtils.showMessageDialog(
            context,
            "Your account is not verified yet. "
            "Please contact the host!");
      }
    };
    Function(int code, Object error) onError = (int code, Object error) {
      setState(() {
        loading = false;
      });

      switch (code) {
        case codes.UserAlreadyExists:
          viewUtils.showMessageDialog(
              context,
              "Username is already taken."
              " Chose a different one");
          break;
        case codes.InvalidPassword:
          viewUtils.showMessageDialog(context, "Invalid username or password");
          break;
        default:
          viewUtils.showMessageDialog(context, "Server is not reachable!");
          break;
      }
    };

    setState(() {
      loading = true;
    });
    if (signUp) {
      userServer.signUp(user, onSuccess, onError);
    } else {
      userServer.login(user, onSuccess, onError);
    }
  }

  List<Widget> textFields() {
    return <Widget>[
      new _Input("Server address", serverAddressController, serverAddressFocus,
          (String text) {
        FocusScope.of(context).requestFocus(usernameFocus);
      }),
      new _Input("Username", usernameController, usernameFocus, (String text) {
        FocusScope.of(context).requestFocus(passwordFocus);
      }),
      new _Input(
        "Password",
        passwordController,
        passwordFocus,
        (String text) {
          if (signUp) {
            FocusScope.of(context).requestFocus(confirmPasswordFocus);
          } else {
            onSubmit();
          }
        },
        secure: true,
        action: signUp ? TextInputAction.next : TextInputAction.done,
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return new Scaffold(
        body: new Center(
          child: new CircularProgressIndicator(),
        ),
      );
    }

    List<Widget> textFields = this.textFields();

    return new Scaffold(
      body: new Padding(
        padding: EdgeInsets.all(16.0),
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            new Expanded(
              child: new Card(
                child: new Stack(
                  children: <Widget>[
                    new ListView.builder(
                      itemCount: textFields.length,
                      itemBuilder: (BuildContext context, int index) {
                        return textFields[index];
                      },
                      padding: EdgeInsets.all(16.0),
                    ),
                    new Align(
                      alignment: Alignment(1.0, 1.0),
                      child: new Padding(
                        padding: EdgeInsets.all(16.0),
                        child: new FloatingActionButton(
                          onPressed: onSubmit,
                          child: new Icon(Icons.done),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              flex: 3,
            ),
            new Expanded(
              child: new Center(
                child: new CupertinoButton(
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
      {Key key, this.secure = false, this.action = TextInputAction.next})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new TextField(
      decoration: new InputDecoration(
        labelText: name,
      ),
      textInputAction: action,
      controller: controller,
      obscureText: secure,
      autocorrect: false,
      textCapitalization: TextCapitalization.none,
      focusNode: focusNode,
      onSubmitted: onSubmitted,
    );
  }
}
