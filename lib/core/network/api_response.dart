/// A typed, successful HTTP response.
///
/// [T] is the parsed body type, for example `List<UserModel>`.
class ApiResponse<T> {
  /// Wraps the parsed body [data] and the HTTP [statusCode].
  const ApiResponse({required this.data, required this.statusCode});

  /// The response body, already converted into [T].
  final T data;

  /// The HTTP status code (e.g. 200 or 201).
  final int statusCode;

  /// Readable description, handy in logs.
  @override
  String toString() => 'ApiResponse(statusCode: $statusCode, data: $data)';
}
