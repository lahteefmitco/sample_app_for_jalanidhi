import 'package:material_ui/material_ui.dart';

/// One tile of the dashboard's navigation menu: what it shows and which
/// screen it opens.
class HomeMenuItem {
  /// Creates a menu entry. `const`, so the whole menu list can be a
  /// compile-time constant.
  const HomeMenuItem({
    required this.label,
    required this.icon,
    required this.routeName,
  });

  /// Text under the icon, e.g. "Users".
  final String label;

  /// Icon shown on the tile.
  final IconData icon;

  /// Route opened when the tile is tapped (one of `RouteNames`).
  final String routeName;

  /// Readable description used in logs and while debugging.
  @override
  String toString() => 'HomeMenuItem(label: $label, routeName: $routeName)';
}
