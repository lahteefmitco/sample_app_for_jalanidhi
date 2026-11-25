import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/cubit/album_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/models/photo_model.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/widgets/photo_tile.dart';

/// Responsive grid of photo tiles; the tile width adapts to the window.
///
/// It gets the photos from its parent (the screen's BlocBuilder), so it does
/// not listen to the Cubit itself.
class PhotoGrid extends StatelessWidget {
  /// Creates a grid showing [photos].
  const PhotoGrid({super.key, required this.photos});

  /// The photos to show, in order.
  final List<PhotoModel> photos;

  /// Builds a lazily created grid: tiles are only built when they scroll
  /// into view.
  @override
  Widget build(BuildContext context) {
    // Only used to forward taps; no rebuild is needed when the Cubit changes.
    final AlbumDetailsCubit cubit = context.read<AlbumDetailsCubit>();
    // Keeps the grid from growing too wide on large screens.
    return MaxWidthContainer(
      child: GridView.builder(
        padding: EdgeInsets.all(AppDimensions.pagePadding),
        // Each tile is at most this wide; the grid picks the column count.
        // `math.max(120, ...)` keeps tiles readable on very small windows.
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: math.max(120, AppDimensions.width(30, max: 200)),
          mainAxisSpacing: AppDimensions.gap,
          crossAxisSpacing: AppDimensions.gap,
        ),
        itemCount: photos.length,
        itemBuilder: (BuildContext context, int index) {
          final PhotoModel photo = photos[index];
          // One tappable thumbnail; a tap opens the photo details sheet.
          return PhotoTile(
            photo: photo,
            onTap: () => cubit.onPhotoTapped(photo),
          );
        },
      ),
    );
  }
}
