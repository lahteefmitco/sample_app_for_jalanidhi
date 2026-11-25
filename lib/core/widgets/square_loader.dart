import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

/// The app's progress animation: four squares moving in a loop (Lottie).
///
/// It replaces the Material `CircularProgressIndicator` everywhere:
///  * [SquareLoader] - the animation itself, centered,
///  * `ProgressDialog` - shows it above the screen while a request runs,
///  * `CommonLoader` - shows it inside a screen while its data loads.
///
/// Two animation files exist because the squares must contrast with the
/// background: white squares in dark mode, dark squares in light mode.
class SquareLoader extends StatelessWidget {
  /// Creates the loader. [size] is the width and height of the animation.
  const SquareLoader({super.key, this.size = 160});

  /// Asset shown in dark mode (white squares).
  static const String darkAsset = 'assets/animation/square_loader_dark.json';

  /// Asset shown in light mode (dark squares).
  static const String lightAsset = 'assets/animation/square_loader_light.json';

  /// Width and height of the animation, in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    // Pick the animation whose squares contrast with the current theme.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Lottie.asset(
          isDark ? darkAsset : lightAsset,
          // If the animation file cannot be loaded, show nothing instead of
          // crashing the screen.
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return const SizedBox.shrink();
              },
        ),
      ),
    );
  }
}
