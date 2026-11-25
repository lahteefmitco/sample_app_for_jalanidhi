import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// State of the search box and the author filter at the top of the list.
///
/// Kept separate from the list so that typing in the search box only
/// rebuilds the header widgets, not the whole list.
@immutable
class PostListHeaderState {
  /// Creates the header state. By default: empty search, all authors.
  const PostListHeaderState({
    this.query = '',
    this.selectedUserId,
    this.users = const <UserModel>[],
  });

  /// Text currently typed in the search box (used to show the clear button).
  final String query;

  /// Id of the author picked in the filter; `null` means "all authors".
  final int? selectedUserId;

  /// Every user, used to build the entries of the author filter menu.
  final List<UserModel> users;

  /// Short text used in logs; prints only the number of users.
  @override
  String toString() =>
      'PostListHeaderState(query: $query, selectedUserId: $selectedUserId, '
      'users: ${users.length})';
}

/// The visible page of posts plus pagination data.
@immutable
class PostListContentState {
  /// Creates the content state. By default nothing has been loaded yet.
  const PostListContentState({
    this.status = ViewStatus.initial,
    this.posts = const <PostModel>[],
    this.authors = const <int, String>{},
    this.totalMatches = 0,
    this.hasMore = false,
    this.errorMessage,
  });

  /// Decides which view the list area shows (loader, error, empty or list).
  final ViewStatus status;

  /// Posts shown right now (only the pages revealed so far).
  final List<PostModel> posts;

  /// Author name per user id, so each tile can show who wrote the post.
  final Map<int, String> authors;

  /// How many posts match the search and filter in total (all pages).
  final int totalMatches;

  /// `true` when the "Load more" button should be shown.
  final bool hasMore;

  /// Message shown by the error view when [status] is error.
  final String? errorMessage;

  /// Short text used in logs; prints only the number of posts.
  @override
  String toString() =>
      'PostListContentState(status: $status, posts: ${posts.length}, '
      'totalMatches: $totalMatches, hasMore: $hasMore, '
      'errorMessage: $errorMessage)';
}

/// Post list state, split in two groups so header and content rebuild
/// independently (each widget selects only its own group with a BlocSelector).
@immutable
class PostListBuildState {
  /// Creates the build state from its two groups.
  const PostListBuildState({
    this.header = const PostListHeaderState(),
    this.content = const PostListContentState(),
  });

  /// Search text and author filter (the bar at the top).
  final PostListHeaderState header;

  /// Loading status, visible posts and pagination (the list below the bar).
  final PostListContentState content;

  /// Text used in logs.
  @override
  String toString() => 'PostListBuildState(header: $header, content: $content)';
}

/// Full state of the post list screen: the build state plus the one-time
/// effect (snackbar, dialog, navigation …). Short name used by widgets and
/// the Cubit.
typedef PostListState = ScreenState<PostListBuildState>;
