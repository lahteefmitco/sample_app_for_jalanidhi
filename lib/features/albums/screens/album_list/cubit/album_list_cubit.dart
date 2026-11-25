import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/utils/extensions.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_list/cubit/album_list_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/album_repository.dart';

/// Cubit of the album list: loads albums and filters them by title.
///
/// It keeps its working data in private fields and turns them into a fresh,
/// immutable [AlbumListBuildState] in [_render]. Navigation and error
/// snackbars are emitted as one-time effects.
class AlbumListCubit extends ScreenCubit<AlbumListBuildState> {
  /// Creates the Cubit in the `initial` status. The route in
  /// `app_routes.dart` calls [load] right after creating it.
  AlbumListCubit({required this._albumRepository})
    : super(const AlbumListBuildState(), name: 'AlbumListCubit');

  /// Where the albums are fetched from (it may return a cached list).
  final AlbumRepository _albumRepository;

  /// Text controller of the search box.
  ///
  /// Owned by the Cubit (so the text survives widget rebuilds), disposed in
  /// [close].
  final TextEditingController searchController = TextEditingController();

  // Working data. The immutable build state is rebuilt from these fields.

  /// Every album returned by the repository, before filtering.
  List<AlbumModel> _all = const <AlbumModel>[];

  /// The albums that match [_query]; this is what the list shows.
  List<AlbumModel> _visible = const <AlbumModel>[];

  /// The current search text, exactly as typed.
  String _query = '';

  /// Current content status (loading, loaded, empty, error ...).
  ViewStatus _status = ViewStatus.initial;

  /// User-friendly error text, set only when [_status] is `error`.
  String? _errorMessage;

  /// Copies the working fields into a new [AlbumListBuildState] and emits it,
  /// so the BlocBuilder in `AlbumListView` rebuilds.
  ///
  /// The list is copied as unmodifiable so widgets cannot change it by
  /// accident.
  void _render() {
    emitBuild(
      AlbumListBuildState(
        status: _status,
        query: _query,
        albums: List<AlbumModel>.unmodifiable(_visible),
        errorMessage: _errorMessage,
      ),
    );
  }

  /// Loads the albums.
  ///
  /// Triggered by the route when the screen opens, and with
  /// [forceRefresh] = `true` by pull-to-refresh and the "Retry" button (so the
  /// repository skips its cache). Emits `loading`, then `loaded`/`empty`, or
  /// `error` plus an error snackbar on failure.
  ///
  /// The request uses a `'load'` token: starting another load, or closing
  /// the screen, cancels it. A cancelled request is ignored silently.
  Future<void> load({bool forceRefresh = false}) async {
    // Cancels any earlier load that is still running.
    final RequestToken token = startBlockingRequest('load');
    _status = ViewStatus.loading;
    _errorMessage = null;
    _render();
    try {
      _all = await _albumRepository.getAlbums(
        forceRefresh: forceRefresh,
        requestToken: token,
      );
      // Applies the current search text and emits the result.
      _applyFilter();
    } on Object catch (error) {
      if (isCancellation(error)) {
        return; // the screen was closed or a newer load started
      }
      _status = ViewStatus.error;
      _errorMessage = ErrorHandler.messageFor(error);
      _render();
      showErrorMessage(_errorMessage!);
    } finally {
      // Un-block the screen (ignored if a newer load took over).
      endBlockingRequest(token);
    }
  }

  /// Filters the albums by [query].
  ///
  /// Triggered on every keystroke in the search box (`TextField.onChanged`).
  /// Emits a new build state with the matching albums (or `empty`).
  void onSearchChanged(String query) {
    _query = query;
    _applyFilter();
  }

  /// Opens the details screen of [album].
  ///
  /// Triggered when the user taps an `AlbumListItem`. Emits a navigation
  /// effect; the build state does not change.
  void onAlbumTapped(AlbumModel album) {
    navigateTo(RouteNames.albumDetails, arguments: album);
  }

  /// Rebuilds [_visible] from [_all] and [_query] (case-insensitive title
  /// match), updates the status and emits the new build state.
  void _applyFilter() {
    // Leading/trailing spaces should not affect the search.
    final String query = _query.trim();
    _visible = query.isEmpty
        ? _all
        : _all
              .where(
                (AlbumModel album) => album.title.containsIgnoreCase(query),
              )
              .toList(growable: false);
    _status = _visible.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    _errorMessage = null;
    _render();
  }

  /// Disposes the [searchController] (owned by this Cubit), then cancels the
  /// running requests and closes the Cubit (see `ScreenCubit.close`).
  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
