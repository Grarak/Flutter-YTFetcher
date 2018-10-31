import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

String fromBase64(String data) {
  return String.fromCharCodes(base64.decode(data));
}

String toBase64(String data) {
  return base64.encode(utf8.encode(data));
}

String fromSeconds(int totalSeconds) {
  int minutes = totalSeconds ~/ 60;
  int seconds = totalSeconds % 60;

  String minutesString = minutes < 10 ? "0$minutes" : minutes.toString();
  String secondsString = seconds < 10 ? "0$seconds" : seconds.toString();
  return "$minutesString:$secondsString";
}

class Settings {
  static void setApiKey(String apiKey) {
    saveString("apikey", apiKey);
  }

  static Future<String> getApiKey() {
    return getString("apikey", null);
  }

  static void setHost(String host) {
    saveString("host", host);
  }

  static Future<String> getHost() {
    return getString("host", null);
  }

  static void saveString(String name, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(name, value);
  }

  static Future<String> getString(String name, String defaultValue) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String value = prefs.getString(name);
    return value == null ? defaultValue : value;
  }
}
