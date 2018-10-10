import 'dart:io';
import 'dart:convert';

enum Method { GET, POST }

class Request {
  HttpClient client;

  Request(Method method, Uri uri, Map<String, String> headers, String data,
      void onSuccess(int code, String response), void onError(Object error)) {
    _start(method, uri, headers, data, onSuccess, onError);
  }

  void _start(Method method, Uri uri, Map<String, String> headers, String data,
      void onSuccess(int code, String response), void onError(Object error)) {
    if (client != null) {
      close();
    }

    client = new HttpClient();
    String methodName = method.toString();
    methodName = methodName.substring(methodName.indexOf(".") + 1);

    client.openUrl(methodName, uri).then((HttpClientRequest request) async {
      headers.forEach((String key, String value) {
        request.headers.add(key, value);
      });
      request.followRedirects = false;
      if (data != null) {
        request.contentLength = data.length;
        request.add(utf8.encode(data));
      }

      return request.close();
    }).then((HttpClientResponse response) {
      switch (response.statusCode) {
        case HttpStatus.movedPermanently:
        case HttpStatus.movedTemporarily:
        case HttpStatus.seeOther:
          String newUrl = response.headers.value("location");
          if (newUrl == null) {
            onError(null);
          } else {
            _start(
                method, Uri.parse(newUrl), headers, data, onSuccess, onError);
          }
          return;
      }

      List<int> content = new List();
      response.listen((List<int> buf) {
        content.addAll(buf);
      }, onError: (Object error) {
        close();
        onError(error);
      }, onDone: () {
        close();
        onSuccess(response.statusCode, String.fromCharCodes(content));
      }, cancelOnError: true);
    });
  }

  void close() {
    client.close(force: true);
  }
}
