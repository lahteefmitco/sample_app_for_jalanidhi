import 'package:dio/dio.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_endpoints.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_exception.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_response.dart';
import 'package:sample_app_for_jalanidhi/core/network/dio_interceptors.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';

/// A function that converts decoded JSON (`Map`, `List`, ...) into a typed
/// value, for example `List<UserModel>`.
typedef ResponseParser<T> = T Function(Object? json);

/// The only place in the app that talks to [Dio].
///
/// Repositories call this class; widgets and Cubits never see Dio.
/// Every method:
///  * sends one HTTP request,
///  * turns the JSON body into `T` with the given `parser`,
///  * throws an [ApiException] (never a raw Dio error) when something fails,
///  * can be cancelled through an optional [RequestToken].
class ApiClient {
  /// Creates the client around an already configured [Dio] instance
  /// (see [createDio]).
  ApiClient(this._dio);

  /// The shared HTTP client (base URL, timeouts, interceptors).
  final Dio _dio;

  /// Builds the one shared Dio instance: base URL, timeouts and the
  /// request / response / error interceptors.
  static Dio createDio({String baseUrl = ApiEndpoints.baseUrl}) {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        responseType: ResponseType.json,
      ),
    );
    dio.interceptors.addAll(<Interceptor>[
      RequestInterceptor(),
      ResponseInterceptor(),
      ErrorInterceptor(),
    ]);
    return dio;
  }

  /// Sends a GET request to [path] (relative to the base URL).
  ///
  /// [queryParameters] are appended to the URL (`?postId=1`).
  /// [requestToken] allows the caller to cancel the request.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required ResponseParser<T> parser,
    RequestToken? requestToken,
  }) {
    return _send<T>(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      parser: parser,
      requestToken: requestToken,
    );
  }

  /// Sends a POST request with [data] as the JSON body.
  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required ResponseParser<T> parser,
    RequestToken? requestToken,
  }) {
    return _send<T>(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      parser: parser,
      requestToken: requestToken,
    );
  }

  /// Sends a PUT request (full replacement) with [data] as the JSON body.
  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required ResponseParser<T> parser,
    RequestToken? requestToken,
  }) {
    return _send<T>(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      parser: parser,
      requestToken: requestToken,
    );
  }

  /// Sends a PATCH request (partial update) with [data] as the JSON body.
  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    required ResponseParser<T> parser,
    RequestToken? requestToken,
  }) {
    return _send<T>(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      parser: parser,
      requestToken: requestToken,
    );
  }

  /// Sends a DELETE request.
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required ResponseParser<T> parser,
    RequestToken? requestToken,
  }) {
    return _send<T>(
      method: 'DELETE',
      path: path,
      queryParameters: queryParameters,
      parser: parser,
      requestToken: requestToken,
    );
  }

  /// Shared implementation of every HTTP method above.
  ///
  /// Step 1 sends the request and converts transport failures (no network,
  /// timeout, HTTP 4xx/5xx, cancellation) into an [ApiException].
  /// Step 2 parses the body; a body with the wrong shape becomes
  /// [ApiException.invalidResponse].
  Future<ApiResponse<T>> _send<T>({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    required ResponseParser<T> parser,
    RequestToken? requestToken,
  }) async {
    // Step 1: send the request.
    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        cancelToken: requestToken?.dioCancelToken,
        options: Options(method: method),
      );
    } on DioException catch (error) {
      // ErrorInterceptor has already put an ApiException inside `error`.
      final Object? inner = error.error;
      if (inner is ApiException) {
        throw inner;
      }
      throw ApiException.fromDioException(error);
    }

    // Step 2: turn the JSON body into the requested type.
    try {
      final T parsed = parser(response.data);
      return ApiResponse<T>(
        data: parsed,
        statusCode: response.statusCode ?? 200,
      );
    } on Object {
      // Malformed JSON, wrong types or missing fields.
      throw const ApiException.invalidResponse();
    }
  }
}
