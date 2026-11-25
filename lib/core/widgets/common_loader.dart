import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/square_loader.dart';

/// Centered square loader for content that is loading inside a screen.
class CommonLoader extends StatelessWidget {
  /// Creates the loader; it has no options.
  const CommonLoader({super.key});

  /// Builds the square animation in the middle of the available space.
  @override
  Widget build(BuildContext context) {
    return const SquareLoader(size: 120);
  }
}
