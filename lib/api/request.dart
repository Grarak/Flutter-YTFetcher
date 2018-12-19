import 'dart:io';
import 'dart:convert';

enum Method { GET, POST }

class Request {
  HttpClient client;

  Request(
      Method method,
      Uri uri,
      Map<String, String> headers,
      String data,
      onSuccess(HttpHeaders headers, int code, String response),
      onError(Object error),
      {bool onConnect(int status, Uri uri)}) {
    _start(method, uri, headers, data, onSuccess, onError,
        onConnect: onConnect);
  }

  void _start(
      Method method,
      Uri uri,
      Map<String, String> headers,
      String data,
      void onSuccess(HttpHeaders headers, int code, String response),
      void onError(Object error),
      {bool onConnect(int status, Uri uri)}) async {
    if (client != null) {
      close();
    }

    client = new HttpClient();
    client.connectionTimeout = new Duration(seconds: 2);
    String methodName = method.toString();
    methodName = methodName.substring(methodName.indexOf(".") + 1);

    HttpClientRequest request;
    try {
      request = await client.openUrl(methodName, uri);

      headers.forEach((String key, String value) {
        request.headers.add(key, value);
      });
      request.followRedirects = false;
      if (data != null) {
        List<int> bytes = utf8.encode(data);
        request.contentLength = bytes.length;
        request.add(bytes);
      }
    } on Error catch (error) {
      onError(error);
      close();
      return;
    } on Exception catch (error) {
      onError(error);
      close();
      return;
    }

    request.close().then((HttpClientResponse response) {
      switch (response.statusCode) {
        case HttpStatus.movedPermanently:
        case HttpStatus.movedTemporarily:
        case HttpStatus.seeOther:
          String newUrl = response.headers.value("location");
          if (newUrl == null) {
            onError(null);
          } else {
            _start(method, Uri.parse(newUrl), headers, data, onSuccess, onError,
                onConnect: onConnect);
          }
          return;
      }

      if (onConnect != null && !onConnect(response.statusCode, uri)) {
        close();
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
        onSuccess(response.headers, response.statusCode,
            String.fromCharCodes(content));
      }, cancelOnError: true);
    });
  }

  void close() {
    client.close(force: true);
  }
}
