import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_dimensions.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/busy_guard.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/max_width_container.dart';
import 'package:sample_app_for_jalanidhi/core/widgets/screen_effect_listener.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/cubit/album_list_cubit.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/cubit/album_list_state.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/widgets/album_list_view.dart';

/// Album list page with a title search. Tapping an album opens its photos.
///
/// The [AlbumListCubit] is created and provided by the route in
/// `app_routes.dart` (which also calls `load()`), so this widget only reads it.
class AlbumListScreen extends StatelessWidget {
  /// Creates the album list screen.
  const AlbumListScreen({super.key});

  /// Builds the app bar, the search box and the album content below it.
  @override
  Widget build(BuildContext context) {
    // `read` (not `watch`): this widget only needs the search controller and
    // callbacks; the content rebuilds inside AlbumListView.
    final AlbumListCubit cubit = context.read<AlbumListCubit>();
    // Listens to the Cubit's one-time effects: navigates to the tapped album
    // and shows the error snackbar when loading fails.
    return ScreenEffectListener<AlbumListCubit, AlbumListBuildState>(
      screenName: 'AlbumListScreen',
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.albums)),
        body: BusyGuard<AlbumListCubit, AlbumListBuildState>(
          // Disabled while a request is running.
          child: Column(
            children: <Widget>[
              // Title search box. The controller lives in the Cubit so the
              // typed text survives rebuilds.
              MaxWidthContainer(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.pagePadding,
                    AppDimensions.gap,
                    AppDimensions.pagePadding,
                    0,
                  ),
                  child: TextField(
                    controller: cubit.searchController,
                    onChanged: cubit.onSearchChanged,
                    decoration: const InputDecoration(
                      hintText: AppStrings.search,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              // Content: loader / error / empty / albums. Expanded gives it all
              // the height left under the search box.
              const Expanded(child: AlbumListView()),
            ],
          ),
        ),
      ),
    );
  }
}
