import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';

/// Icon, title and subtitle shown above the login and register forms.
///
/// Shared by both pages so they look the same; it is purely visual.
class AuthHeader extends StatelessWidget {
  /// Creates the header with the given [title] and [subtitle].
  const AuthHeader({super.key, required this.title, required this.subtitle});

  /// Big bold text, e.g. "Welcome back".
  final String title;

  /// Smaller grey text under the title (app name or a disclaimer).
  final String subtitle;

  /// Builds the round logo followed by the title and subtitle.
  @override
  Widget build(BuildContext context) {
    // Read once so every child uses colors from the current theme.
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        // Round app logo; its size scales with the screen width.
        CircleAvatar(
          radius: AppDimensions.width(8, min: 28, max: 40),
          backgroundColor: colors.primaryContainer,
          child: Icon(
            Icons.water_drop_outlined,
            color: colors.onPrimaryContainer,
            size: AppDimensions.iconSize,
          ),
        ),
        SizedBox(height: AppDimensions.gap),
        // Title.
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimensions.fontHeadline,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppDimensions.gapSmall),
        // Subtitle in a softer color.
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: AppDimensions.fontBody,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
