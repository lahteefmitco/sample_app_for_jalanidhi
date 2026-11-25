import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_empty_view.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_error_widget.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/common_loader.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/responsive_list_grid.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/cubit/album_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/cubit/album_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/widgets/album_list_item.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';

/// Switches between loader, error, empty and the album list/grid.
///
/// It is a separate widget so only this part of the page rebuilds when the
/// albums change; the search box above it stays untouched.
class AlbumListView extends StatelessWidget {
  /// Creates the album content area.
  const AlbumListView({super.key});

  /// Builds the view that matches the current status.
  @override
  Widget build(BuildContext context) {
    // Used for callbacks only (retry, refresh, tap); never rebuilds this.
    final AlbumListCubit cubit = context.read<AlbumListCubit>();
    // Rebuilds whenever a new BuildState is emitted. `buildStateChanged`
    // skips rebuilds caused only by effects (navigation, snackbar), because
    // those reuse the same BuildState.
    return BlocBuilder<AlbumListCubit, AlbumListState>(
      buildWhen: buildStateChanged,
      builder: (BuildContext context, AlbumListState state) {
        // The part of the state this view renders.
        final AlbumListBuildState build = state.build;
        switch (build.status) {
          // Nothing loaded yet: show a spinner.
          case ViewStatus.initial:
          case ViewStatus.loading:
            return const CommonLoader();
          // Loading failed: show the message and a "Retry" button that
          // bypasses the cache.
          case ViewStatus.error:
            return CommonErrorWidget(
              message: build.errorMessage ?? '',
              onRetry: () => cubit.load(forceRefresh: true),
            );
          // No album at all, or none matches the search.
          case ViewStatus.empty:
            return const CommonEmptyView(
              message: AppStrings.noAlbums,
              icon: Icons.photo_album_outlined,
            );
          // Albums are ready: pull down to refresh, list on phones and grid
          // on wider screens.
          case ViewStatus.loaded:
            return RefreshIndicator(
              onRefresh: () => cubit.load(forceRefresh: true),
              child: ResponsiveListGrid(
                itemCount: build.albums.length,
                tileHeight: 88,
                itemBuilder: (BuildContext context, int index) {
                  final AlbumModel album = build.albums[index];
                  // One tappable album tile; a tap opens its photos.
                  return AlbumListItem(
                    album: album,
                    onTap: () => cubit.onAlbumTapped(album),
                  );
                },
              ),
            );
        }
      },
    );
  }
}
