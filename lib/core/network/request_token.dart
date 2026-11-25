import 'package:dio/dio.dart';

/// A handle that can cancel one or more HTTP requests that are still running.
///
/// Why it exists:
///  * When the user leaves a screen while its data is still loading, the
///    request is useless: cancelling it saves bandwidth and battery.
///  * When the user pulls to refresh (or taps "Retry") while a load is still
///    running, the older request must not overwrite the newer result.
///
/// How it is used:
///  1. A screen Cubit asks for a token: `newRequestToken('load')`.
///  2. The Cubit passes the token to a repository method.
///  3. The repository passes it to [ApiClient], which hands it to Dio.
///  4. Calling [cancel] stops the request; the awaiting code receives an
///     `ApiException` whose type is `ApiErrorType.cancelled`.
///
/// This class wraps Dio's `CancelToken` so that Cubits and repositories never
/// import Dio themselves (only `core/network` may do that).
class RequestToken {
  /// Creates a token that is not cancelled yet.
  RequestToken();

  /// The Dio token that really performs the cancellation.
  final CancelToken _cancelToken = CancelToken();

  /// `true` once [cancel] has been called.
  bool get isCancelled => _cancelToken.isCancelled;

  /// Cancels every request that was started with this token.
  ///
  /// Calling it more than once is harmless. [reason] only appears in logs.
  void cancel([String reason = 'Request cancelled']) {
    if (isCancelled) {
      return;
    }
    _cancelToken.cancel(reason);
  }

  /// The underlying Dio token.
  ///
  /// Only `ApiClient` should read this; everything else uses [cancel] and
  /// [isCancelled].
  CancelToken get dioCancelToken => _cancelToken;

  /// Readable description, handy in logs.
  @override
  String toString() => 'RequestToken(isCancelled: $isCancelled)';
}
