import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';

/// One statistic tile (icon, big number, label) of the dashboard.
///
/// Purely visual: the parent (`HomeSummaryGrid`) passes ready-to-show text.
class HomeSummaryCard extends StatelessWidget {
  /// Creates a tile showing [value] with its [icon] and [label].
  const HomeSummaryCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  /// Icon at the top of the tile.
  final IconData icon;

  /// Small text under the number, e.g. "Users".
  final String label;

  /// The big number, already formatted as text (e.g. "10" or "90 (45%)").
  final String value;

  /// Builds the card with icon, value and label stacked vertically.
  @override
  Widget build(BuildContext context) {
    // Read once so every child uses colors from the current theme.
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Statistic icon.
            Icon(icon, color: colors.primary, size: AppDimensions.iconSize),
            SizedBox(height: AppDimensions.gapSmall),
            // Big number; scaleDown shrinks it instead of overflowing on
            // narrow tiles.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: AppDimensions.fontHeadline,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Label; cut with "..." if it does not fit on one line.
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: AppDimensions.fontSmall,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
