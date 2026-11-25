import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';

/// Centered icon + message for lists with nothing to show.
class CommonEmptyView extends StatelessWidget {
  /// Creates the view; the icon defaults to an empty inbox.
  const CommonEmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  /// Text explaining why the list is empty.
  final String message;

  /// Large icon shown above [message].
  final IconData icon;

  /// Builds the centered icon and message.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Big, muted icon.
            Icon(
              icon,
              size: AppDimensions.iconSize * 2,
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: AppDimensions.gap),
            // The explanation text.
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: AppDimensions.fontBody),
            ),
          ],
        ),
      ),
    );
  }
}
