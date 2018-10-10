import 'dart:io';

import 'request.dart';
import 'codes.dart' as codes;

class Server {
  static const String _API_VERSION = "v1";

  String host;
  List<Request> requests = new List();
  bool closed = false;

  Server(this.host);

  void get(String path, onSuccess(String response),
      onError(int code, Object error)) {
    _doRequest(Method.GET, path, null, onSuccess, onError);
  }

  void post(String path, String data, onSuccess(String response),
      onError(int code, Object error)) {
    _doRequest(Method.POST, path, data, onSuccess, onError);
  }

  void _doRequest(Method method, String path, String data,
      onSuccess(String response), onError(int code, Object error)) {
    if (closed) {
      return;
    }

    Map<String, String> headers = new Map();
    if (data != null) {
      headers["content-type"] = "application/json";
    }
    requests.add(new Request(
        method,
        Uri.parse(host + "/api/" + _API_VERSION + "/" + path),
        headers,
        data, (int code, String response) {
      if (code == HttpStatus.ok) {
        onSuccess(response);
      } else {
        int code = codes.getStatusCode(response);
        onError(code == null ? codes.Unknown : code, null);
      }
    }, (Object error) {
      onError(codes.Unknown, error);
    }));
  }

  void close() {
    closed = true;

    for (Request request in requests) {
      request.close();
    }
  }
}
