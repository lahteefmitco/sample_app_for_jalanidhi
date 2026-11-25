import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';

/// Full-width filled button with an optional leading icon.
class CommonButton extends StatelessWidget {
  /// Creates the button; pass a null [onPressed] to disable it.
  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  /// Text shown on the button.
  final String label;

  /// Called on tap; when null the button is shown disabled.
  final VoidCallback? onPressed;

  /// Optional icon shown before [label].
  final IconData? icon;

  /// Builds a plain or icon button, depending on whether [icon] is set.
  @override
  Widget build(BuildContext context) {
    // Label and style are shared by both button variants below.
    final Text text = Text(
      label,
      style: TextStyle(fontSize: AppDimensions.fontBody),
    );
    final ButtonStyle style = FilledButton.styleFrom(
      minimumSize: Size.fromHeight(AppDimensions.width(12, min: 44, max: 52)),
    );
    // Button without an icon.
    if (icon == null) {
      return FilledButton(onPressed: onPressed, style: style, child: text);
    }
    // Button with a leading icon.
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon),
      label: text,
    );
  }
}
