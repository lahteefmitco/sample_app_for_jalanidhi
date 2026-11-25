import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';

/// What the comment list renders: status, query and the visible page.
///
/// Immutable: the Cubit creates a new instance for every change, which is
/// how `buildStateChanged` knows the list must rebuild.
@immutable
class CommentListBuildState {
  /// Creates a build state. The defaults describe the screen before anything
  /// was loaded.
  const CommentListBuildState({
    this.status = ViewStatus.initial,
    this.query = '',
    this.comments = const <CommentModel>[],
    this.totalMatches = 0,
    this.hasMore = false,
    this.errorMessage,
  });

  /// Which view to show: loader, error, empty or the list.
  final ViewStatus status;

  /// The search text the comments were filtered with.
  final String query;

  /// The comments shown right now (only the revealed pages, not every
  /// match).
  final List<CommentModel> comments;

  /// How many comments match [query] in total; shown on the "Load more"
  /// button as "shown/total".
  final int totalMatches;

  /// `true` when more matches exist than [comments] holds, so the "Load
  /// more" button is shown.
  final bool hasMore;

  /// Text shown by the error view; `null` unless [status] is `error`.
  final String? errorMessage;

  /// Short description for logs (prints only the comment count).
  @override
  String toString() =>
      'CommentListBuildState(status: $status, query: $query, '
      'comments: ${comments.length}, totalMatches: $totalMatches, '
      'hasMore: $hasMore, errorMessage: $errorMessage)';
}

/// Full state of the comment list screen: the [CommentListBuildState] plus
/// the one-time effect handled by `ScreenEffectListener`.
typedef CommentListState = ScreenState<CommentListBuildState>;
