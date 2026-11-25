import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_colors.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/models/photo_model.dart';

/// Thumbnail with a colored fallback.
///
/// The thumbnail host used by JSONPlaceholder is often unreachable, so the
/// tile falls back to the color encoded in the URL instead of showing an
/// error.
class PhotoTile extends StatelessWidget {
  /// Creates a tile for [photo] that calls [onTap] when tapped.
  const PhotoTile({super.key, required this.photo, required this.onTap});

  /// The photo to show.
  final PhotoModel photo;

  /// Called when the user taps the tile (the grid opens the details sheet).
  final VoidCallback onTap;

  /// Builds the rounded thumbnail, with a colored box while it loads or if it
  /// fails to load.
  @override
  Widget build(BuildContext context) {
    // Color from the URL, or the app's default when the URL has none.
    final Color fallback = Color(
      photo.placeholderColor ?? AppColors.fallbackPhoto.toARGB32(),
    );
    // Tells screen readers what the tile shows and that it is tappable.
    return Semantics(
      label: photo.title,
      button: true,
      // Ripple effect and tap handling.
      child: InkWell(
        onTap: onTap,
        // Rounded corners for the image.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            photo.thumbnailUrl,
            fit: BoxFit.cover,
            // The image could not be loaded: show the fallback color and the
            // photo id instead of a broken-image icon.
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stackTrace) =>
                    ColoredBox(
                      color: fallback,
                      child: Center(
                        child: Text(
                          '#${photo.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            // While downloading (`progress != null`) show a faded fallback
            // color; once done, show the image itself (`child`).
            loadingBuilder:
                (
                  BuildContext context,
                  Widget child,
                  ImageChunkEvent? progress,
                ) => progress == null
                ? child
                : ColoredBox(color: fallback.withValues(alpha: 0.4)),
          ),
        ),
      ),
    );
  }
}
