import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';

/// One album tile: icon, title and ids.
///
/// It is a plain widget (no Cubit access): the parent passes the album and
/// what to do on tap, which keeps the tile easy to reuse and test.
class AlbumListItem extends StatelessWidget {
  /// Creates a tile for [album] that calls [onTap] when tapped.
  const AlbumListItem({super.key, required this.album, required this.onTap});

  /// The album to show.
  final AlbumModel album;

  /// Called when the user taps the tile (opens the album details).
  final VoidCallback onTap;

  /// Builds the card: album icon, title + ids, and a chevron.
  @override
  Widget build(BuildContext context) {
    // Theme colors, so the tile follows light/dark mode.
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      // Clips the InkWell ripple to the card's rounded corners.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppDimensions.gap),
          child: Row(
            children: <Widget>[
              // Leading album icon.
              Icon(Icons.photo_album_outlined, color: colors.primary),
              SizedBox(width: AppDimensions.gap),
              // Title and ids take all the remaining width.
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Album title (at most two lines).
                    Text(
                      album.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: AppDimensions.fontBody,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Secondary line: album id and owner id.
                    Text(
                      'Album #${album.id} · user #${album.userId}',
                      style: TextStyle(
                        fontSize: AppDimensions.fontSmall,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Hints that tapping opens another page.
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
