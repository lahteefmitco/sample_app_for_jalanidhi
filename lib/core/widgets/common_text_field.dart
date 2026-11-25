import 'package:material_ui/material_ui.dart';

/// Text field whose controller and error text are owned by a screen Cubit.
///
/// It is stateless: the Cubit keeps the [controller] and passes the current
/// validation message as [errorText].
class CommonTextField extends StatelessWidget {
  /// Creates the field; only [controller] and [label] are required.
  const CommonTextField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.autofillHints,
  });

  /// Holds the field's text (owned by the screen Cubit).
  final TextEditingController controller;

  /// Floating label shown inside the field.
  final String label;

  /// Validation message shown under the field; null means "valid".
  final String? errorText;

  /// Hides the text (for passwords).
  final bool obscureText;

  /// Which keyboard to show (email, number, ...).
  final TextInputType? keyboardType;

  /// What the keyboard's action key does (next field, done, ...).
  final TextInputAction? textInputAction;

  /// Optional icon at the start of the field.
  final IconData? prefixIcon;

  /// Optional widget at the end of the field (e.g. show-password toggle).
  final Widget? suffixIcon;

  /// Number of visible lines; ignored (always 1) when [obscureText] is true.
  final int maxLines;

  /// Called on every text change.
  final ValueChanged<String>? onChanged;

  /// Called when the user presses the keyboard's action key.
  final ValueChanged<String>? onSubmitted;

  /// Hints for password managers / autofill (e.g. email, password).
  final Iterable<String>? autofillHints;

  /// Builds an outlined Material [TextField] from the options above.
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      // Obscured text must stay on one line (Flutter requires it).
      maxLines: obscureText ? 1 : maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
