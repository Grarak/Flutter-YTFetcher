import 'dart:io';
import 'dart:convert';

import 'server.dart';

class HistoryServer extends Server {
  HistoryServer(String host) : super(host);

  void retrieve(String apiKey, onSuccess(List<String> ids),
      onError(int code, Object error)) {
    post("users/history/list", "{\"apikey\":\"$apiKey\"}",
        (HttpHeaders headers, String response) {
      List<dynamic> unparsedJson = json.decode(response);
      List<String> ids = new List();
      for (dynamic id in unparsedJson) {
        ids.add(id);
      }
      onSuccess(ids);
    }, onError);
  }
}
