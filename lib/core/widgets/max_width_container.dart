import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';

/// Centers [child] and stops it from becoming excessively wide on desktop/web.
class MaxWidthContainer extends StatelessWidget {
  /// Creates the container; [maxWidth] defaults to
  /// [Breakpoints.maxContentWidth].
  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
  });

  /// The content to limit.
  final Widget child;

  /// Widest the content may become, in logical pixels.
  final double maxWidth;

  /// Builds the top-centered, width-limited box around [child].
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
