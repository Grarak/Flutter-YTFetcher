import 'dart:io';
import 'dart:collection';

import 'request.dart';
import 'codes.dart' as codes;

class Server {
  static const String _API_VERSION = "v1";

  String host;
  Queue<Request> requests = new ListQueue();

  Server(this.host);

  Uri buildUri(String path) {
    return Uri.parse("$host/api/$_API_VERSION/$path");
  }

  void get(String path, onSuccess(HttpHeaders headers, String response),
      onError(int code, Object error),
      {bool onConnect(int status, Uri uri)}) {
    getUri(buildUri(path), onSuccess, onError, onConnect: onConnect);
  }

  void getUri(Uri url, onSuccess(HttpHeaders headers, String response),
      onError(int code, Object error),
      {bool onConnect(int status, Uri uri)}) {
    _doRequest(Method.GET, url, null, onSuccess, onError, onConnect: onConnect);
  }

  void post(
      String path,
      String data,
      onSuccess(HttpHeaders headers, String response),
      onError(int code, Object error),
      {bool onConnect(int status, Uri uri)}) {
    postUri(buildUri(path), data, onSuccess, onError, onConnect: onConnect);
  }

  void postUri(
      Uri uri,
      String data,
      onSuccess(HttpHeaders headers, String response),
      onError(int code, Object error),
      {bool onConnect(int status, Uri uri)}) {
    _doRequest(Method.POST, uri, data, onSuccess, onError,
        onConnect: onConnect);
  }

  void _doRequest(
      Method method,
      Uri uri,
      String data,
      onSuccess(HttpHeaders headers, String response),
      onError(int code, Object error),
      {bool onConnect(int status, Uri uri)}) {
    Map<String, String> headers = new Map();
    if (data != null) {
      headers["content-type"] = "application/json";
    }
    requests.addLast(new Request(method, uri, headers, data,
        (HttpHeaders headers, int code, String response) {
      if (code == HttpStatus.ok) {
        onSuccess(headers, response);
      } else {
        int code = codes.getStatusCode(response);
        onError(code == null ? codes.Unknown : code, null);
      }
    }, (Object error) {
      onError(codes.Unknown, error);
    }, onConnect: onConnect));
  }

  void close() {
    while (requests.length != 0) {
      requests.removeFirst().close();
    }
  }
}
