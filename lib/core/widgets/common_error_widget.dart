import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';

/// Centered error message with an optional retry button.
class CommonErrorWidget extends StatelessWidget {
  /// Creates the view; without [onRetry] no retry button is shown.
  const CommonErrorWidget({super.key, required this.message, this.onRetry});

  /// User-friendly error text.
  final String message;

  /// Called when the user taps "Retry"; null hides the button.
  final VoidCallback? onRetry;

  /// Builds the centered icon, message and optional retry button.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Big error icon in the theme's error color.
            Icon(
              Icons.error_outline,
              size: AppDimensions.iconSize * 2,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: AppDimensions.gap),
            // The error message.
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppDimensions.fontBody),
            ),
            // Retry button, only when the caller can retry.
            if (onRetry != null) ...<Widget>[
              SizedBox(height: AppDimensions.gap),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text(AppStrings.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
