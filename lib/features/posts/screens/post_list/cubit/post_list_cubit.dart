import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/core/utils/extensions.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_list/cubit/post_list_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

/// Business logic of the post list screen.
///
/// Search, author filter, client-side pagination ("Load more"), and the
/// delete action (after a confirmation dialog).
class PostListCubit extends ScreenCubit<PostListBuildState> {
  /// Creates the Cubit. Repositories are injected by GetIt.
  PostListCubit({required this._postRepository, required this._userRepository})
    : super(const PostListBuildState(), name: 'PostListCubit');

  /// Request purpose (used with [newRequestToken]) of the full load.
  static const String _loadRequest = 'load';

  /// Request purpose of the quiet refresh after returning from another page.
  /// It has its own purpose so it does not cancel a running full load.
  static const String _refreshRequest = 'refresh';

  /// Prefix of the confirmation id, e.g. `delete:12`.
  static const String _deletePrefix = 'delete:';

  /// Source of the posts.
  final PostRepository _postRepository;

  /// Source of the authors (names for the list and the filter menu).
  final UserRepository _userRepository;

  /// Controller of the search box. Owned by the Cubit, disposed in [close].
  final TextEditingController searchController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Working data. The immutable state is rebuilt from these fields.
  // ---------------------------------------------------------------------------

  /// Every post returned by the repository.
  List<PostModel> _allPosts = const <PostModel>[];

  /// The posts currently displayed (first [_visibleCount] matches).
  List<PostModel> _page = const <PostModel>[];

  /// Every user (for the author filter menu).
  List<UserModel> _users = const <UserModel>[];

  /// Author name per user id, e.g. `{1: 'Leanne Graham'}`.
  Map<int, String> _authors = const <int, String>{};

  /// Current search text.
  String _query = '';

  /// Selected author; `null` means "all authors".
  int? _selectedUserId;

  /// How many matching posts are shown (grows by one page on "Load more").
  int _visibleCount = AppConstants.pageSize;

  /// How many posts match the search and filter in total.
  int _totalMatches = 0;

  /// `true` when more matching posts can be revealed.
  bool _hasMore = false;

  /// Loading status of the list.
  ViewStatus _status = ViewStatus.initial;

  /// Message shown by the error view.
  String? _errorMessage;

  /// Builds the header group (search + filter) from the working data.
  PostListHeaderState _header() {
    return PostListHeaderState(
      query: _query,
      selectedUserId: _selectedUserId,
      users: _users,
    );
  }

  /// Builds the content group (list + pagination) from the working data.
  PostListContentState _content() {
    return PostListContentState(
      status: _status,
      posts: List<PostModel>.unmodifiable(_page),
      authors: _authors,
      totalMatches: _totalMatches,
      hasMore: _hasMore,
      errorMessage: _errorMessage,
    );
  }

  /// Emits a new content group and keeps the current header instance.
  void _emitContent() {
    emitBuild(PostListBuildState(header: build.header, content: _content()));
  }

  /// Emits new header and content groups.
  void _emitAll() {
    emitBuild(PostListBuildState(header: _header(), content: _content()));
  }

  /// Loads posts and users at the same time.
  ///
  /// Triggered when the screen opens (by the route), by the retry button of
  /// the error view and by pull-to-refresh (both with `forceRefresh: true`).
  /// Emits the content group as loading, then header + content with the
  /// first page, or an error content plus an error snackbar.
  ///
  /// A load that is still running is cancelled first.
  Future<void> load({bool forceRefresh = false}) async {
    final RequestToken token = startBlockingRequest(_loadRequest);
    _status = ViewStatus.loading;
    _errorMessage = null;
    _emitContent();
    try {
      // Filled by the two parallel requests below; `late` because they get
      // their values inside the callbacks.
      late final List<PostModel> posts;
      late final List<UserModel> users;
      // Both requests run in parallel; Future.wait rethrows the first error.
      await Future.wait(<Future<void>>[
        _postRepository
            .getPosts(forceRefresh: forceRefresh, requestToken: token)
            .then((List<PostModel> value) {
              posts = value;
            }),
        _userRepository
            .getUsers(forceRefresh: forceRefresh, requestToken: token)
            .then((List<UserModel> value) {
              users = value;
            }),
      ]);
      _allPosts = posts;
      _users = users;
      _authors = <int, String>{
        for (final UserModel user in users) user.id: user.name,
      };
      // A fresh load always starts again at page one.
      _visibleCount = AppConstants.pageSize;
      _applyFilters();
    } on Object catch (error) {
      if (isCancellation(error)) {
        return; // the screen was closed or a newer load started
      }
      _status = ViewStatus.error;
      _errorMessage = ErrorHandler.messageFor(error);
      _emitContent();
      showErrorMessage(_errorMessage!);
    } finally {
      // Un-block the screen (ignored if a newer load took over).
      endBlockingRequest(token);
    }
  }

  /// Called by `PostSearchField` on every keystroke in the search box.
  /// Restarts at page one and emits header + content.
  void onSearchChanged(String query) {
    _query = query;
    _visibleCount = AppConstants.pageSize;
    _applyFilters();
  }

  /// Called by the clear (x) button of `PostSearchField`.
  /// Clears the search box and shows every post again (emits header + content).
  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  /// Called by `PostAuthorFilter` when an author is picked; `null` shows
  /// every author. Restarts at page one and emits header + content.
  void onAuthorChanged(int? userId) {
    _selectedUserId = userId;
    _visibleCount = AppConstants.pageSize;
    _applyFilters();
  }

  /// Called by the "Load more" button below the list.
  ///
  /// Client-side pagination: reveals the next page of already loaded posts
  /// (no network request) and emits header + content.
  void loadMore() {
    if (!_hasMore) {
      return;
    }
    _visibleCount += AppConstants.pageSize;
    _applyFilters();
  }

  /// Called when a `PostListItem` is tapped.
  /// Emits a navigation effect that opens the details page of [post].
  void onPostTapped(PostModel post) {
    navigateTo(RouteNames.postDetails, arguments: post.id);
  }

  /// Called by the "New post" floating button.
  /// Emits a navigation effect that opens an empty post form.
  void onCreatePressed() {
    navigateTo(RouteNames.postForm);
  }

  /// Called by "Edit" in the menu of a `PostListItem`.
  /// Emits a navigation effect that opens the post form filled with [post].
  void onEditPressed(PostModel post) {
    navigateTo(RouteNames.postForm, arguments: post.id);
  }

  /// Called by "Delete" in the menu of a `PostListItem`.
  /// Emits a confirmation-dialog effect; nothing is deleted until the user
  /// confirms (see [onConfirmed]).
  void onDeletePressed(PostModel post) {
    emitEffect(
      ShowConfirmationEffect(
        actionId: '$_deletePrefix${post.id}',
        title: AppStrings.confirmDeletePostTitle,
        message: AppStrings.confirmDeletePostMessage,
        confirmLabel: AppStrings.delete,
        // Deleting cannot be undone: the dialog turns red.
        isDestructive: true,
      ),
    );
  }

  /// Called by `ScreenEffectListener` after the user confirms the dialog.
  /// [actionId] looks like `delete:12`; any other id is ignored.
  @override
  void onConfirmed(String actionId) {
    if (!actionId.startsWith(_deletePrefix)) {
      return;
    }
    // The post id after the prefix; `null` if the text is not a number.
    final int? id = int.tryParse(actionId.substring(_deletePrefix.length));
    if (id != null) {
      _delete(id);
    }
  }

  /// Deletes the post [id] while the progress dialog is shown.
  ///
  /// Emits: progress shown, then the updated list, progress hidden and a
  /// success snackbar; or progress hidden and an error snackbar.
  ///
  /// Not cancellable on purpose: a delete should finish once started.
  Future<void> _delete(int id) async {
    // A request is already running: ignore a second tap / Enter key press.
    if (isBusy) {
      return;
    }
    showProgress();
    try {
      await _postRepository.deletePost(id);
      _allPosts = await _postRepository.getPosts();
      _applyFilters();
      hideProgress();
      showSuccessMessage(AppStrings.postDeleted);
    } on Object catch (error) {
      hideProgress();
      showError(error);
    }
  }

  /// Called by `ScreenEffectListener` when the user comes back from details
  /// or the form: posts may have changed, so the list is refreshed from the
  /// repository. [result] tells what happened there.
  @override
  void onNavigationReturn(Object? result) {
    _refreshFromRepository(result);
  }

  /// Re-reads the posts (from memory, no loader) and reports [result].
  ///
  /// Emits the updated list, plus a success snackbar when [result] is
  /// `'saved'` or `'deleted'`; on failure only an error snackbar.
  Future<void> _refreshFromRepository(Object? result) async {
    final RequestToken token = newRequestToken(_refreshRequest);
    try {
      _allPosts = await _postRepository.getPosts(requestToken: token);
      _applyFilters();
      if (result == 'saved') {
        showSuccessMessage(AppStrings.postSaved);
      }
      if (result == 'deleted') {
        showSuccessMessage(AppStrings.postDeleted);
      }
    } on Object catch (error) {
      if (isCancellation(error)) {
        return;
      }
      showError(error);
    }
  }

  /// Applies search + author filter, then keeps the first [_visibleCount]
  /// matches, and emits.
  ///
  /// Called after every load, filter change, "Load more", delete and refresh,
  /// so the visible page is always computed in one place.
  void _applyFilters() {
    // Leading/trailing spaces should not affect the search.
    final String query = _query.trim();
    // Every post that passes the filters (all pages, not only the visible).
    final List<PostModel> matches = _allPosts
        .where((PostModel post) {
          final bool matchesAuthor =
              _selectedUserId == null || post.userId == _selectedUserId;
          final bool matchesQuery =
              query.isEmpty ||
              post.title.containsIgnoreCase(query) ||
              post.body.containsIgnoreCase(query);
          return matchesAuthor && matchesQuery;
        })
        .toList(growable: false);

    _page = matches.take(_visibleCount).toList(growable: false);
    _totalMatches = matches.length;
    _hasMore = _page.length < matches.length;
    _status = matches.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
    _errorMessage = null;
    cubitLog(
      'showing ${_page.length}/${matches.length} posts '
      '(query: "$query", author: $_selectedUserId)',
      funtionName: '_applyFilters',
    );
    _emitAll();
  }

  /// Disposes the search controller, cancels requests and closes the Cubit.
  ///
  /// Called automatically by `BlocProvider` when the screen is removed.
  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
