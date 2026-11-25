import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_empty_view.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/cubit/album_details_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/cubit/album_details_state.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/widgets/photo_grid.dart';

/// Album details page: a responsive grid of the album's photos.
///
/// The app bar title is the album title. Tapping a photo opens a bottom
/// sheet with its details.
///
/// The [AlbumDetailsCubit] is created and provided by the route in
/// `app_routes.dart` (which also calls `load()`), so this widget only reads it.
class AlbumDetailsScreen extends StatelessWidget {
  /// Creates the album details screen. It takes no arguments: the album
  /// comes from the [AlbumDetailsCubit] provided above this widget.
  const AlbumDetailsScreen({super.key});

  /// Builds the app bar and switches the body between loader, error, empty
  /// and the photo grid depending on the Cubit's status.
  @override
  Widget build(BuildContext context) {
    // `read` (not `watch`): we only need the Cubit to call its methods and to
    // read the album; rebuilding is handled by the BlocBuilder below.
    final AlbumDetailsCubit cubit = context.read<AlbumDetailsCubit>();
    // Listens to the Cubit's one-time effects: opens the photo bottom sheet
    // and shows the error snackbar when loading fails.
    return ScreenEffectListener<AlbumDetailsCubit, AlbumDetailsBuildState>(
      screenName: 'AlbumDetailsScreen',
      child: Scaffold(
        // The album is an argument of the Cubit, so its title is available at
        // once (no need to wait for the photos to load).
        appBar: AppBar(
          title: Text(
            cubit.album.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Rebuilds the body whenever a new BuildState is emitted.
        // `buildStateChanged` skips rebuilds caused only by effects
        // (snackbar, bottom sheet), because those reuse the same BuildState.
        body: BusyGuard<AlbumDetailsCubit, AlbumDetailsBuildState>(
          // Disabled while a request is running.
          child: BlocBuilder<AlbumDetailsCubit, AlbumDetailsState>(
            buildWhen: buildStateChanged,
            builder: (BuildContext context, AlbumDetailsState state) {
              // The part of the state this screen renders.
              final AlbumDetailsBuildState build = state.build;
              switch (build.status) {
                // Nothing loaded yet: show a spinner.
                case ViewStatus.initial:
                case ViewStatus.loading:
                  return const CommonLoader();
                // Loading failed: show the message and a "Retry" button.
                case ViewStatus.error:
                  return CommonErrorWidget(
                    message: build.errorMessage ?? '',
                    onRetry: cubit.load,
                  );
                // The album has no photos.
                case ViewStatus.empty:
                  return const CommonEmptyView(
                    message: AppStrings.noPhotos,
                    icon: Icons.photo_library_outlined,
                  );
                // Photos are ready: show them in a grid.
                case ViewStatus.loaded:
                  return PhotoGrid(photos: build.photos);
              }
            },
          ),
        ),
      ),
    );
  }
}
