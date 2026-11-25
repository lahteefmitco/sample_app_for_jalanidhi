/// Small helpers that turn decoded JSON into typed models.
///
/// A wrong shape throws a `TypeError`, which `ApiClient` converts into an
/// `ApiException.invalidResponse`.
///
/// [parseList] expects a JSON array of objects and converts each object with
/// [fromJson] (e.g. `UserModel.fromJson`).
List<T> parseList<T>(
  Object? json,
  T Function(Map<String, dynamic> json) fromJson,
) {
  return (json as List<dynamic>)
      .map((dynamic item) => fromJson(item as Map<String, dynamic>))
      .toList(growable: false);
}

/// Expects a single JSON object and converts it with [fromJson].
T parseObject<T>(Object? json, T Function(Map<String, dynamic> json) fromJson) {
  return fromJson(json as Map<String, dynamic>);
}
