import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_constants.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/utils/extensions.dart';
import 'package:sample_app_for_jalanidhi/features/comments/screens/comment_list/cubit/comment_list_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';

/// Cubit of the comment list: search and client-side pagination over the
/// 500 comments, and the details bottom sheet.
///
/// All comments are fetched once; "pagination" only reveals more of the
/// already fetched list, [AppConstants.pageSize] items at a time. The working
/// data lives in private fields and [_render] turns it into a fresh, immutable
/// [CommentListBuildState].
class CommentListCubit extends ScreenCubit<CommentListBuildState> {
  /// Creates the Cubit in the `initial` status. The route in
  /// `app_routes.dart` calls [load] right after creating it.
  CommentListCubit({required this._commentRepository})
    : super(const CommentListBuildState(), name: 'CommentListCubit');

  /// Where the comments are fetched from (it may return a cached list).
  final CommentRepository _commentRepository;

  /// Text controller of the search box.
  ///
  /// Owned by the Cubit (so the text survives widget rebuilds, and
  /// [clearSearch] can empty it), disposed in [close].
  final TextEditingController searchController = TextEditingController();

  // Working data. The immutable build state is rebuilt from these fields.

  /// Every comment returned by the repository, before filtering.
  List<CommentModel> _all = const <CommentModel>[];

  /// The matching comments that are currently shown (the first
  /// [_visibleCount] matches).
  List<CommentModel> _page = const <CommentModel>[];

  /// The current search text, exactly as typed.
  String _query = '';

  /// How many matching comments may be shown; grows by one page on every
  /// "Load more" tap and is reset to one page on a new search or load.
  int _visibleCount = AppConstants.pageSize;

  /// How many comments match [_query] in total (shown as "x/total").
  int _totalMatches = 0;

  /// `true` when more matches exist than are shown, i.e. "Load more" is
  /// visible.
  bool _hasMore = false;

  /// Current content status (loading, loaded, empty, error ...).
  ViewStatus _status = ViewStatus.initial;

  /// User-friendly error text, set only when [_status] is `error`.
  String? _errorMessage;

  /// Copies the working fields into a new [CommentListBuildState] and emits
  /// it, so the BlocBuilder in `CommentListView` rebuilds.
  ///
  /// The list is copied as unmodifiable so widgets cannot change it by
  /// accident.
  void _render() {
    emitBuild(
      CommentListBuildState(
        status: _status,
        query: _query,
        comments: List<CommentModel>.unmodifiable(_page),
        totalMatches: _totalMatches,
        hasMore: _hasMore,
        errorMessage: _errorMessage,
      ),
    );
  }

  /// Loads all comments and shows the first page.
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
      _all = await _commentRepository.getComments(
        forceRefresh: forceRefresh,
        requestToken: token,
      );
      // Fresh data: start again from the first page.
      _visibleCount = AppConstants.pageSize;
      _applyFilters();
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

  /// Filters the comments by [query] and goes back to the first page.
  ///
  /// Triggered on every keystroke in the search box (`TextField.onChanged`)
  /// and by [clearSearch]. Emits a new build state with the first page of
  /// matches (or `empty`).
  void onSearchChanged(String query) {
    _query = query;
    _visibleCount = AppConstants.pageSize;
    _applyFilters();
  }

  /// Empties the search box and shows every comment again.
  ///
  /// Clears the controller too, because the text field would otherwise keep
  /// showing the old text. Emits the same as [onSearchChanged].
  void clearSearch() {
    searchController.clear();
    onSearchChanged('');
  }

  /// Reveals the next page of already fetched comments.
  ///
  /// Triggered by the "Load more" button under the list. Does nothing when
  /// every match is already shown; otherwise emits a build state with one
  /// more page of comments.
  void loadMore() {
    if (!_hasMore) return;
    _visibleCount += AppConstants.pageSize;
    _applyFilters();
  }

  /// Opens a bottom sheet with the full comment.
  ///
  /// Triggered when the user taps a `CommentListItem`. Emits a
  /// [ShowInfoSheetEffect]; the build state does not change.
  void onCommentTapped(CommentModel comment) {
    emitEffect(
      ShowInfoSheetEffect(
        title: 'Comment #${comment.id}',
        // One label/value row per detail shown in the sheet.
        fields: <MapEntry<String, String>>[
          MapEntry<String, String>('Name', comment.name),
          MapEntry<String, String>('Email', comment.email),
          MapEntry<String, String>('Post', '#${comment.postId}'),
          MapEntry<String, String>('Body', comment.body),
        ],
      ),
    );
  }

  /// Filters by the search text and slices the visible page.
  ///
  /// A comment matches when its name, email or body contains the search text
  /// (case-insensitive). Updates the paging fields and the status, then emits
  /// the new build state.
  void _applyFilters() {
    // Leading/trailing spaces should not affect the search.
    final String query = _query.trim();
    // Every comment that matches the search (not only the visible page).
    final List<CommentModel> matches = query.isEmpty
        ? _all
        : _all
              .where(
                (CommentModel c) =>
                    c.name.containsIgnoreCase(query) ||
                    c.email.containsIgnoreCase(query) ||
                    c.body.containsIgnoreCase(query),
              )
              .toList(growable: false);
    _page = matches.take(_visibleCount).toList(growable: false);
    _totalMatches = matches.length;
    _hasMore = _page.length < matches.length;
    _status = matches.isEmpty ? ViewStatus.empty : ViewStatus.loaded;
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
