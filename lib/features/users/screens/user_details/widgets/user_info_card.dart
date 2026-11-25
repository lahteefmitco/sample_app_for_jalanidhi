import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// Card with avatar, name, username and contact details of a user.
class UserInfoCard extends StatelessWidget {
  /// Creates the card for [user].
  const UserInfoCard({super.key, required this.user});

  /// The user whose details are shown.
  final UserModel user;

  /// Builds the header (avatar + name) followed by one row per detail.
  @override
  Widget build(BuildContext context) {
    // Theme colours, used for the avatar.
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header: avatar next to name and username.
            Row(
              children: <Widget>[
                // Avatar with the first letter of the name ('?' if no name);
                // its size follows the window width within 24-36.
                CircleAvatar(
                  radius: AppDimensions.width(7, min: 24, max: 36),
                  backgroundColor: colors.primaryContainer,
                  foregroundColor: colors.onPrimaryContainer,
                  child: Text(user.name.isEmpty ? '?' : user.name[0]),
                ),
                SizedBox(width: AppDimensions.gap),
                // Name (bold) and @username, using the remaining width.
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: AppDimensions.fontTitle,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text('@${user.username}'),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDimensions.gap),
            // Contact details, one icon + text row each.
            _InfoRow(icon: Icons.email_outlined, text: user.email),
            _InfoRow(icon: Icons.phone_outlined, text: user.phone),
            _InfoRow(icon: Icons.language, text: user.website),
            _InfoRow(icon: Icons.place_outlined, text: user.address.formatted),
            // Company name and its slogan.
            _InfoRow(
              icon: Icons.business_outlined,
              text: '${user.company.name} — ${user.company.catchPhrase}',
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + text row used inside [UserInfoCard] (email, phone, address …).
class _InfoRow extends StatelessWidget {
  /// Creates a row showing [icon] followed by [text].
  const _InfoRow({required this.icon, required this.text});

  /// Small icon that tells what kind of detail this is.
  final IconData icon;

  /// The detail itself (may wrap onto several lines).
  final String text;

  /// Builds the icon and the text side by side.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppDimensions.gapSmall),
      child: Row(
        // Keeps the icon at the top when the text wraps.
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Slightly smaller than a normal icon.
          Icon(icon, size: AppDimensions.iconSize * 0.8),
          SizedBox(width: AppDimensions.gap),
          // Text fills the remaining width and wraps if needed.
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: AppDimensions.fontBody),
            ),
          ),
        ],
      ),
    );
  }
}
