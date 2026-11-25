import 'package:material_ui/material_ui.dart';

/// Brand and status colors used across the app.
///
/// Prefer `Theme.of(context).colorScheme` in widgets; use these only for
/// colors the theme does not provide.
abstract final class AppColors {
  /// Seed color the light and dark color schemes are generated from.
  static const Color seed = Color(0xFF0B7A9E);

  /// Background of success snackbars (e.g. "Post saved").
  static const Color success = Color(0xFF2E7D32);

  /// Background of error snackbars.
  static const Color error = Color(0xFFC62828);

  /// Background of neutral, informational snackbars.
  static const Color info = Color(0xFF1565C0);

  /// Placeholder color shown when a photo cannot be loaded.
  static const Color fallbackPhoto = Color(0xFF90A4AE);
}
