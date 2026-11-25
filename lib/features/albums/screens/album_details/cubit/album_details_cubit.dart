import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/cubit/album_details_state.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/models/photo_model.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/repositories/photo_repository.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';

/// Cubit of the album details screen: loads the photos of one [album].
///
/// It keeps its working data in private fields and turns them into a fresh,
/// immutable [AlbumDetailsBuildState] in [_render]. One-time UI actions (the
/// photo bottom sheet, error snackbars) are emitted as effects.
class AlbumDetailsCubit extends ScreenCubit<AlbumDetailsBuildState> {
  /// Creates the Cubit for [album]. It starts in the `initial` status; the
  /// router calls [load] right after creating it.
  AlbumDetailsCubit({required this.album, required this._photoRepository})
    : super(const AlbumDetailsBuildState(), name: 'AlbumDetailsCubit');

  /// The album whose photos are shown. Passed in by the album list when the
  /// user taps an album; the screen also uses it for the app bar title.
  final AlbumModel album;

  /// Where the photos are fetched from.
  final PhotoRepository _photoRepository;

  // Working data. The immutable build state is rebuilt from these fields.

  /// Current content status (loading, loaded, empty, error ...).
  ViewStatus _status = ViewStatus.initial;

  /// The photos of [album], as returned by the repository.
  List<PhotoModel> _photos = const <PhotoModel>[];

  /// User-friendly error text, set only when [_status] is `error`.
  String? _errorMessage;

  /// Copies the working fields into a new [AlbumDetailsBuildState] and emits
  /// it, so the BlocBuilder on the screen rebuilds.
  ///
  /// The list is copied as unmodifiable so widgets cannot change it by
  /// accident.
  void _render() {
    emitBuild(
      AlbumDetailsBuildState(
        status: _status,
        photos: List<PhotoModel>.unmodifiable(_photos),
        errorMessage: _errorMessage,
      ),
    );
  }

  /// Loads the photos of [album].
  ///
  /// Triggered by the router when the screen opens and by the "Retry" button
  /// of the error view. Emits `loading`, then `loaded`/`empty` on success, or
  /// `error` plus an error snackbar on failure.
  ///
  /// The request uses a `'load'` token: starting another load, or closing
  /// the screen, cancels it. A cancelled request is ignored silently.
  Future<void> load() async {
    // Cancels any earlier load that is still running.
    final RequestToken token = startBlockingRequest('load');
    _status = ViewStatus.loading;
    _errorMessage = null;
    _render();
    try {
      _photos = await _photoRepository.getPhotosByAlbum(
        album.id,
        requestToken: token,
      );
      _status = _photos.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
      _render();
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

  /// Opens a bottom sheet with the photo details.
  ///
  /// Triggered when the user taps a tile in the `PhotoGrid`. Emits a
  /// [ShowInfoSheetEffect]; the build state does not change.
  void onPhotoTapped(PhotoModel photo) {
    emitEffect(
      ShowInfoSheetEffect(
        title: 'Photo #${photo.id}',
        // One label/value row per detail shown in the sheet.
        fields: <MapEntry<String, String>>[
          MapEntry<String, String>('Title', photo.title),
          MapEntry<String, String>('Album', '#${photo.albumId}'),
          MapEntry<String, String>('Image URL', photo.url),
          MapEntry<String, String>('Thumbnail URL', photo.thumbnailUrl),
        ],
      ),
    );
  }
}
