import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_colors.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/page_transitions.dart';

/// Light and dark Material 3 themes, both generated from [AppColors.seed].
abstract final class AppTheme {
  /// Theme used in day (light) mode.
  static ThemeData light() => _build(Brightness.light);

  /// Theme used in night (dark) mode.
  static ThemeData dark() => _build(Brightness.dark);

  /// Shared theme recipe, so light and dark only differ by [brightness].
  static ThemeData _build(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.seed,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(centerTitle: false),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      // Every screen change slides right-to-left (and left-to-right on back),
      // on every platform, so the app feels the same everywhere.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: SlideRightToLeftTransitionsBuilder(),
          TargetPlatform.iOS: SlideRightToLeftTransitionsBuilder(),
          TargetPlatform.macOS: SlideRightToLeftTransitionsBuilder(),
          TargetPlatform.windows: SlideRightToLeftTransitionsBuilder(),
          TargetPlatform.linux: SlideRightToLeftTransitionsBuilder(),
          TargetPlatform.fuchsia: SlideRightToLeftTransitionsBuilder(),
        },
      ),
    );
  }
}
