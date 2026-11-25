import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';

/// Builds the JSON answer for one route. It receives the request (to read
/// query parameters or the body) and may throw a `DioException` to simulate
/// a network error.
typedef RouteHandler = Object? Function(RequestOptions options);

/// Offline stand-in for JSONPlaceholder: routes `"GET /users"` style keys to
/// canned JSON, so tests never touch the network.
class FakeBackend implements HttpClientAdapter {
  /// Creates a backend answering [routes]. [latency] delays every answer,
  /// which lets tests cancel a request while it is still running.
  FakeBackend(this.routes, {this.latency = Duration.zero});

  /// Canned answers, keyed by `"METHOD /path"`.
  final Map<String, RouteHandler> routes;

  /// Simulated network delay of every request.
  final Duration latency;

  /// Every request seen, as `"METHOD /path"`.
  final List<String> requests = <String>[];

  /// How many times the request [key] (e.g. `"GET /users"`) was made.
  int count(String key) => requests.where((String r) => r == key).length;

  /// Creates a [Dio] configured like the app's one, but answered by this
  /// fake backend instead of the real network.
  Dio createDio() {
    final Dio dio = ApiClient.createDio(baseUrl: 'https://fake.test');
    dio.httpClientAdapter = this;
    return dio;
  }

  /// Creates an [ApiClient] that talks to this fake backend.
  ApiClient createClient() => ApiClient(createDio());

  /// Answers one request from [routes] (or with a 404 if no route matches).
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String key = '${options.method} ${options.path}';
    requests.add(key);
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final RouteHandler? handler = routes[key];
    if (handler == null) {
      return _json(<String, String>{'error': 'not found'}, 404);
    }
    final Object? body = handler(options); // may throw DioException
    return _json(body, 200);
  }

  /// Wraps [body] as a JSON response with the HTTP [status] code.
  ResponseBody _json(Object? body, int status) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>['application/json'],
      },
    );
  }

  /// Nothing to release: the fake backend holds no connections.
  @override
  void close({bool force = false}) {}
}
