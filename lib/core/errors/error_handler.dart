import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/errors/app_exception.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';

/// Converts any thrown object into a message that is safe to show to users.
abstract final class ErrorHandler {
  /// Logs [error] and returns its user-friendly message.
  ///
  /// Our own [AppException]s already carry a safe message; anything else
  /// (a bug, a plugin error) gets a generic text so no details leak to users.
  static String messageFor(Object error, {StackTrace? stackTrace}) {
    errorLog('$error', funtionName: 'ErrorHandler.messageFor');
    if (error is AppException) {
      return error.message;
    }
    return AppStrings.unexpectedError;
  }
}
