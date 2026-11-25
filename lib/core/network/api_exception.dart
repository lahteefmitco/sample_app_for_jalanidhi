import 'package:dio/dio.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';

/// The kind of failure an [ApiException] describes.
///
/// Cubits can use it to react differently, e.g. ignore [cancelled].
enum ApiErrorType {
  /// No connection, or the connection could not be trusted.
  network,

  /// The server took too long to connect, send or answer.
  timeout,

  /// The server answered with an error status (4xx / 5xx).
  badResponse,

  /// The server answered, but the body had an unexpected shape.
  invalidResponse,

  /// The request was cancelled on purpose (through a `RequestToken`).
  cancelled,

  /// Anything Dio could not classify.
  unknown,
}

/// Failure of an HTTP call, already translated to a user-safe message.
class ApiException extends AppException {
  /// Creates an error of [type] with a user-safe [message].
  const ApiException({
    required this.type,
    required String message,
    this.statusCode,
  }) : super(message);

  /// Error used when the response body cannot be parsed into the model.
  const ApiException.invalidResponse()
    : type = ApiErrorType.invalidResponse,
      statusCode = null,
      super(AppStrings.invalidResponse);

  /// Translates a raw Dio [error] into an [ApiException] whose message can
  /// be shown to the user.
  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          type: ApiErrorType.timeout,
          message: AppStrings.timeoutError,
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          type: ApiErrorType.network,
          message: AppStrings.networkError,
        );
      case DioExceptionType.badResponse:
        // HTTP status of the failed response (404 gets its own message).
        final int? status = error.response?.statusCode;
        return ApiException(
          type: ApiErrorType.badResponse,
          statusCode: status,
          message: status == 404
              ? 'The requested item was not found.'
              : AppStrings.serverError,
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          type: ApiErrorType.network,
          message: AppStrings.networkError,
        );
      case DioExceptionType.cancel:
        return const ApiException(
          type: ApiErrorType.cancelled,
          message: 'The request was cancelled.',
        );
      case DioExceptionType.unknown:
        return const ApiException(
          type: ApiErrorType.unknown,
          message: AppStrings.networkError,
        );
    }
  }

  /// What kind of failure this is.
  final ApiErrorType type;

  /// HTTP status code, only set for [ApiErrorType.badResponse].
  final int? statusCode;

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'ApiException(type: $type, statusCode: $statusCode, message: $message)';
}
