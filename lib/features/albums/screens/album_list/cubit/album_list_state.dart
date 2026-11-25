import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';

/// What the album list renders: status, query and visible albums.
///
/// Immutable: the Cubit creates a new instance for every change, which is
/// how `buildStateChanged` knows the list must rebuild.
@immutable
class AlbumListBuildState {
  /// Creates a build state. The defaults describe the screen before anything
  /// was loaded.
  const AlbumListBuildState({
    this.status = ViewStatus.initial,
    this.query = '',
    this.albums = const <AlbumModel>[],
    this.errorMessage,
  });

  /// Which view to show: loader, error, empty or the list.
  final ViewStatus status;

  /// The search text the [albums] were filtered with.
  final String query;

  /// The albums that match [query], in display order.
  final List<AlbumModel> albums;

  /// Text shown by the error view; `null` unless [status] is `error`.
  final String? errorMessage;

  /// Short description for logs (prints only the album count).
  @override
  String toString() =>
      'AlbumListBuildState(status: $status, query: $query, '
      'albums: ${albums.length}, errorMessage: $errorMessage)';
}

/// Full state of the album list screen: the [AlbumListBuildState] plus the
/// one-time effect handled by `ScreenEffectListener`.
typedef AlbumListState = ScreenState<AlbumListBuildState>;
