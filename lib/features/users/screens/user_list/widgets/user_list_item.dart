import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// One user tile: avatar, name, email, city and company.
///
/// It has no state of its own: the parent passes the [user] to show and
/// what to do when the tile is tapped.
class UserListItem extends StatelessWidget {
  /// Creates a tile for [user]; [onTap] runs when the tile is tapped.
  const UserListItem({super.key, required this.user, required this.onTap});

  /// The user shown in this tile.
  final UserModel user;

  /// Called when the tile is tapped (the list opens the user details page).
  final VoidCallback onTap;

  /// Builds the card with the avatar, the three text lines and an arrow.
  @override
  Widget build(BuildContext context) {
    // Theme colours, used for the avatar and the grey third line.
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      // Makes the whole card tappable with a ripple effect.
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimensions.gap,
            vertical: AppDimensions.gapSmall,
          ),
          child: Row(
            children: <Widget>[
              // Avatar with the first letter of the name ('?' if no name).
              CircleAvatar(
                backgroundColor: colors.primaryContainer,
                foregroundColor: colors.onPrimaryContainer,
                child: Text(user.name.isEmpty ? '?' : user.name[0]),
              ),
              SizedBox(width: AppDimensions.gap),
              // Text lines take all the remaining width.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Line 1: name in bold.
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppDimensions.fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Line 2: email.
                    Text(
                      user.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: AppDimensions.fontSmall),
                    ),
                    // Line 3: city and company in a softer colour.
                    Text(
                      '${user.address.city} · ${user.company.name}',
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
              // Arrow hinting that the tile opens another page.
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
