import 'package:material_ui/material_ui.dart';

/// The theme the user picked. [ThemeMode.system] (follow the device) is the
/// default; [ThemeMode.light] is "day" and [ThemeMode.dark] is "night".
@immutable
class ThemeState {
  /// Creates the state; by default the app follows the device setting.
  const ThemeState({this.mode = ThemeMode.system});

  /// The theme mode `MaterialApp` should use.
  final ThemeMode mode;

  /// Readable description, handy in logs.
  @override
  String toString() => 'ThemeState(mode: ${mode.name})';
}
