import 'server.dart';
import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'user_server.g.dart';

@JsonSerializable(includeIfNull: false)
class User {
  String apikey;
  String name;
  String password;
  bool admin;
  bool verified;

  User({this.apikey, this.name, this.password, this.admin, this.verified});

  factory User.fromJson(String data) => _$UserFromJson(json.decode(data));

  @override
  String toString() {
    return json.encode(_$UserToJson(this));
  }
}

class UserServer extends Server {
  UserServer(String host) : super(host);

  void signUp(
      User user, onSuccess(User user), onError(int code, Object error)) {
    post("users/signup", user.toString(), (String response) {
      onSuccess(User.fromJson(response));
    }, onError);
  }

  void login(User user, onSuccess(User user), onError(int code, Object error)) {
    post("users/login", user.toString(), (String response) {
      onSuccess(User.fromJson(response));
    }, onError);
  }
}
