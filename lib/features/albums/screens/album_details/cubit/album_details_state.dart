import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/albums/screens/album_details/models/photo_model.dart';

/// What the album details screen renders: status and photos.
///
/// Immutable: the Cubit creates a new instance for every change, which is
/// how `buildStateChanged` knows the screen must rebuild.
@immutable
class AlbumDetailsBuildState {
  /// Creates a build state. The defaults describe the screen before anything
  /// was loaded.
  const AlbumDetailsBuildState({
    this.status = ViewStatus.initial,
    this.photos = const <PhotoModel>[],
    this.errorMessage,
  });

  /// Which view to show: loader, error, empty or the grid.
  final ViewStatus status;

  /// The photos to show in the grid (empty until loaded).
  final List<PhotoModel> photos;

  /// Text shown by the error view; `null` unless [status] is `error`.
  final String? errorMessage;

  /// Short description for logs (prints only the photo count, not every
  /// photo).
  @override
  String toString() =>
      'AlbumDetailsBuildState(status: $status, photos: ${photos.length}, '
      'errorMessage: $errorMessage)';
}

/// Full state of the album details screen: the [AlbumDetailsBuildState] plus
/// the one-time effect handled by `ScreenEffectListener`.
typedef AlbumDetailsState = ScreenState<AlbumDetailsBuildState>;
