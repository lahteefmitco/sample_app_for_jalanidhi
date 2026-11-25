import 'package:dio/dio.dart';
import 'package:sample_app_for_jalanidhi/core/network/api_exception.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';

/// Key under which the request start time is stored in `options.extra`,
/// so the response / error interceptor can compute the duration.
const String _startedAtKey = 'started_at';

/// Header names that must never reach the logs.
const Set<String> _sensitiveHeaders = <String>{
  'authorization',
  'cookie',
  'set-cookie',
  'x-api-key',
};

/// Returns a copy of [headers] with sensitive values replaced by `***`.
Map<String, dynamic> _redact(Map<String, dynamic> headers) {
  return <String, dynamic>{
    for (final MapEntry<String, dynamic> entry in headers.entries)
      entry.key: _sensitiveHeaders.contains(entry.key.toLowerCase())
          ? '***'
          : entry.value,
  };
}

/// Adds default headers and logs outgoing requests (debug builds only).
class RequestInterceptor extends Interceptor {
  /// Runs before every request is sent.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers.putIfAbsent('Accept', () => 'application/json');
    options.extra[_startedAtKey] = DateTime.now().millisecondsSinceEpoch;
    repositoryLog(
      '--> ${options.method} ${options.uri} '
      'query=${options.queryParameters} headers=${_redact(options.headers)}',
      name: 'API',
      funtionName: 'onRequest',
    );
    handler.next(options);
  }
}

/// Logs responses (status and duration only, never bodies).
class ResponseInterceptor extends Interceptor {
  /// Runs after every successful response.
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    repositoryLog(
      '<-- ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri} (${_elapsed(response.requestOptions)} ms)',
      name: 'API',
      funtionName: 'onResponse',
    );
    handler.next(response);
  }
}

/// Maps every [DioException] to an [ApiException] carried in `error`.
class ErrorInterceptor extends Interceptor {
  /// Runs when a request fails (network, timeout, HTTP error, cancel).
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final ApiException apiException = ApiException.fromDioException(err);
    if (err.type == DioExceptionType.cancel) {
      // Cancellation is intentional (screen closed / newer request): not an
      // error, so it is logged as a normal repository event.
      repositoryLog(
        '<-- CANCELLED ${err.requestOptions.method} ${err.requestOptions.uri} '
        '(${_elapsed(err.requestOptions)} ms) reason: ${err.error}',
        name: 'API',
        funtionName: 'onError',
      );
    } else {
      errorLog(
        '<-- ERROR ${err.requestOptions.method} ${err.requestOptions.uri} '
        '(${_elapsed(err.requestOptions)} ms) $apiException',
        name: 'API',
        funtionName: 'onError',
      );
    }
    // Re-wrap the failure so callers receive the ApiException in `error`.
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: apiException,
        stackTrace: err.stackTrace,
        message: err.message,
      ),
    );
  }
}

/// Milliseconds since the request started, or 0 if the start is unknown.
int _elapsed(RequestOptions options) {
  // Start time saved by RequestInterceptor (dynamic: `extra` is untyped).
  final Object? started = options.extra[_startedAtKey];
  if (started is int) {
    return DateTime.now().millisecondsSinceEpoch - started;
  }
  return 0;
}
