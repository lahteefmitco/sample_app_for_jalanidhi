import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_colors.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';

/// Centralised snackbar used for every user-facing message.
abstract final class AppSnackbar {
  /// Shows [message] in a floating snackbar colored by [type].
  ///
  /// Any snackbar already visible is hidden first, so messages never queue.
  static void show(
    BuildContext context,
    String message, {
    SnackbarType type = SnackbarType.info,
  }) {
    // Null when there is no Scaffold above (e.g. the screen was closed).
    final ScaffoldMessengerState? messenger = ScaffoldMessenger.maybeOf(
      context,
    );
    if (messenger == null) return;
    // Background color that matches the message type.
    final Color color = switch (type) {
      SnackbarType.success => AppColors.success,
      SnackbarType.error => AppColors.error,
      SnackbarType.info => AppColors.info,
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          width: _width(context),
        ),
      );
  }

  /// Keeps snackbars readable on wide screens.
  static double? _width(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return width > 600 ? 480 : null;
  }
}
