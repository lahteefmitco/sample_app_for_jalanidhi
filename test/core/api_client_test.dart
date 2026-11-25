import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_client.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_exception.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_response.dart';
import 'package:sample_app_for_jalanidhi/core/network/json_parsers.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

import '../helpers/fake_backend.dart';
import '../helpers/sample_data.dart';

/// Tests for [ApiClient]: typed parsing of responses, query parameters and
/// how HTTP / Dio errors are turned into [ApiException]s.
///
/// A [FakeBackend] answers the requests, so no real network is used.
void main() {
  test('parses a successful typed response', () async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      'GET /users': (RequestOptions _) => usersJson,
    });
    final ApiResponse<List<UserModel>> response = await backend
        .createClient()
        .get<List<UserModel>>(
          '/users',
          parser: (Object? json) => parseList(json, UserModel.fromJson),
        );
    expect(response.statusCode, 200);
    expect(response.data, hasLength(3));
    expect(response.data.first.name, 'Charlie Brown');
  });

  test('forwards query parameters', () async {
    // Remember the query parameters the backend received.
    Map<String, dynamic>? seen;
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      'GET /comments': (RequestOptions options) {
        seen = options.queryParameters;
        return <Object>[];
      },
    });
    await backend.createClient().get<List<Object?>>(
      '/comments',
      queryParameters: <String, dynamic>{'postId': 7},
      parser: (Object? json) => json as List<Object?>,
    );
    expect(seen, <String, int>{'postId': 7});
  });

  test('maps HTTP 404 to a badResponse ApiException', () async {
    // No routes at all: every request gets a 404.
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{});
    expect(
      backend.createClient().get<Object?>('/missing', parser: (Object? j) => j),
      throwsA(
        isA<ApiException>()
            .having(
              (ApiException e) => e.type,
              'type',
              ApiErrorType.badResponse,
            )
            .having((ApiException e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });

  test('maps malformed payloads to invalidResponse', () async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      'GET /users': (RequestOptions _) => <String, String>{'not': 'a list'},
    });
    expect(
      backend.createClient().get<List<UserModel>>(
        '/users',
        parser: (Object? json) => parseList(json, UserModel.fromJson),
      ),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.type,
          'type',
          ApiErrorType.invalidResponse,
        ),
      ),
    );
  });

  test('maps timeouts and connection errors', () async {
    /// Builds dummy request options for the fake Dio errors below.
    RequestOptions options() => RequestOptions(path: '/x');
    final ApiException timeout = ApiException.fromDioException(
      DioException(
        requestOptions: options(),
        type: DioExceptionType.receiveTimeout,
      ),
    );
    final ApiException network = ApiException.fromDioException(
      DioException(
        requestOptions: options(),
        type: DioExceptionType.connectionError,
      ),
    );
    expect(timeout.type, ApiErrorType.timeout);
    expect(network.type, ApiErrorType.network);
  });

  test('network failures reach callers as ApiException', () async {
    final FakeBackend backend = FakeBackend(<String, RouteHandler>{
      // Simulate "no internet" for this route.
      'GET /users': (RequestOptions options) => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    });
    expect(
      backend.createClient().get<Object?>('/users', parser: (Object? j) => j),
      throwsA(
        isA<ApiException>().having(
          (ApiException e) => e.type,
          'type',
          ApiErrorType.network,
        ),
      ),
    );
  });
}
