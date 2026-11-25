import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/cubit/home_state.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/models/home_menu_item.dart';
import 'package:sample_app_for_jalanidhi/features/home/screens/home/models/home_summary.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/global/models/album_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/auth_user_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/todo_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/album_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/auth_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/todo_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

/// Cubit of the home (dashboard) screen.
///
/// It loads the signed-in user's name and the totals shown on the summary
/// cards, opens the feature screens from the menu and handles logout.
/// Results are emitted as a [HomeBuildState]; snackbars, navigation and the
/// logout confirmation are one-time effects.
class HomeCubit extends ScreenCubit<HomeBuildState> {
  /// Creates the Cubit with every repository the dashboard reads from.
  ///
  /// Called by the route when the home page is opened. It starts in the
  /// `initial` status; the route is expected to call [load] afterwards.
  HomeCubit({
    required this._authRepository,
    required this._userRepository,
    required this._postRepository,
    required this._commentRepository,
    required this._todoRepository,
    required this._albumRepository,
  }) : super(const HomeBuildState(), name: 'HomeCubit');

  /// Request purpose used with [newRequestToken].
  ///
  /// Using the same purpose for every load means a new load automatically
  /// cancels the one still running.
  static const String _loadRequest = 'load';

  /// Id of the "log out" confirmation, checked again in [onConfirmed].
  static const String _logoutAction = 'logout';

  /// Static navigation menu (does not change at runtime).
  ///
  /// Kept here (not in the state) because it never changes, so the menu grid
  /// never needs to rebuild.
  static const List<HomeMenuItem> menuItems = <HomeMenuItem>[
    HomeMenuItem(
      label: AppStrings.users,
      icon: Icons.people_outline,
      routeName: RouteNames.userList,
    ),
    HomeMenuItem(
      label: AppStrings.posts,
      icon: Icons.article_outlined,
      routeName: RouteNames.postList,
    ),
    HomeMenuItem(
      label: AppStrings.comments,
      icon: Icons.comment_outlined,
      routeName: RouteNames.commentList,
    ),
    HomeMenuItem(
      label: AppStrings.todos,
      icon: Icons.checklist_outlined,
      routeName: RouteNames.todoList,
    ),
    HomeMenuItem(
      label: AppStrings.albums,
      icon: Icons.photo_album_outlined,
      routeName: RouteNames.albumList,
    ),
  ];

  /// Gives the signed-in user (for the greeting) and performs logout.
  final AuthRepository _authRepository;

  /// Source of the users list (only its length is shown).
  final UserRepository _userRepository;

  /// Source of the posts list (only its length is shown).
  final PostRepository _postRepository;

  /// Source of the comments list (only its length is shown).
  final CommentRepository _commentRepository;

  /// Source of the todos list (split into completed / pending).
  final TodoRepository _todoRepository;

  /// Source of the albums list (only its length is shown).
  final AlbumRepository _albumRepository;

  // Working data. The immutable build state is rebuilt from these fields.

  /// Loading progress of the summary (initial, loading, loaded, error ...).
  ViewStatus _status = ViewStatus.initial;

  /// Name of the signed-in user; empty when unknown.
  String _userName = '';

  /// Totals shown on the summary cards; `null` until the first load succeeds.
  HomeSummary? _summary;

  /// User-friendly error text shown when the last load failed.
  String? _errorMessage;

  /// Copies the working fields into a fresh, immutable [HomeBuildState] and
  /// emits it, so the greeting and summary widgets can rebuild.
  void _render() {
    emitBuild(
      HomeBuildState(
        status: _status,
        userName: _userName,
        summary: _summary,
        errorMessage: _errorMessage,
      ),
    );
  }

  /// Loads the signed-in user and every count shown on the dashboard.
  /// [showLoader] is false for silent refreshes (e.g. returning from a menu
  /// screen).
  ///
  /// Triggered when the screen opens, by pull-to-refresh and the "retry"
  /// button ([forceRefresh] = `true` skips cached data), and by
  /// [onNavigationReturn]. Emits `loading` (only with [showLoader]), then
  /// `loaded` with the new summary, or `error` plus an error snackbar.
  Future<void> load({bool forceRefresh = false, bool showLoader = true}) async {
    // Cancels a dashboard load that is still running (e.g. pull-to-refresh
    // twice) so an older answer never replaces a newer one.
    final RequestToken token = startBlockingRequest(_loadRequest);
    if (showLoader) {
      _status = ViewStatus.loading;
      _errorMessage = null;
      _render();
    }
    try {
      // `null` when nobody is signed in; the greeting then shows no name.
      final AuthUserModel? user = await _authRepository.currentUser();

      // `late final`: each list is filled by its own request below, once
      // Future.wait has finished all of them.
      late final List<UserModel> users;
      late final List<PostModel> posts;
      late final List<CommentModel> comments;
      late final List<TodoModel> todos;
      late final List<AlbumModel> albums;
      // The five requests run in parallel. Future.wait rethrows the first
      // error unchanged, so the user sees the real reason (e.g. no network).
      await Future.wait<void>(<Future<void>>[
        _userRepository
            .getUsers(forceRefresh: forceRefresh, requestToken: token)
            .then((List<UserModel> value) {
              users = value;
            }),
        _postRepository
            .getPosts(forceRefresh: forceRefresh, requestToken: token)
            .then((List<PostModel> value) {
              posts = value;
            }),
        _commentRepository
            .getComments(forceRefresh: forceRefresh, requestToken: token)
            .then((List<CommentModel> value) {
              comments = value;
            }),
        _todoRepository
            .getTodos(forceRefresh: forceRefresh, requestToken: token)
            .then((List<TodoModel> value) {
              todos = value;
            }),
        _albumRepository
            .getAlbums(forceRefresh: forceRefresh, requestToken: token)
            .then((List<AlbumModel> value) {
              albums = value;
            }),
      ]);

      // Business calculation: split the todos into completed and pending.
      final int completed = todos
          .where((TodoModel todo) => todo.completed)
          .length;
      final HomeSummary summary = HomeSummary(
        userCount: users.length,
        postCount: posts.length,
        commentCount: comments.length,
        albumCount: albums.length,
        completedTodoCount: completed,
        pendingTodoCount: todos.length - completed,
      );
      cubitLog('summary: $summary', funtionName: 'load');
      _userName = user?.name ?? '';
      _summary = summary;
      _status = ViewStatus.loaded;
      _errorMessage = null;
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

  /// Opens the screen behind a menu tile.
  ///
  /// Triggered by tapping a tile in `HomeMenuGrid`; emits a navigation
  /// effect for [item]'s route. When that screen closes, the dashboard
  /// refreshes itself (see [onNavigationReturn]).
  void onMenuItemSelected(HomeMenuItem item) => navigateTo(item.routeName);

  /// Asks the user to confirm the logout.
  ///
  /// Triggered by the logout icon in the app bar; emits a confirmation
  /// dialog effect. The actual logout happens in [onConfirmed].
  void onLogoutPressed() {
    emitEffect(
      const ShowConfirmationEffect(
        actionId: _logoutAction,
        title: AppStrings.confirmLogoutTitle,
        message: AppStrings.confirmLogoutMessage,
        confirmLabel: AppStrings.logout,
      ),
    );
  }

  /// Called by `ScreenEffectListener` after the user pressed "confirm" in a
  /// confirmation dialog; runs the logout when it was the logout dialog.
  @override
  void onConfirmed(String actionId) {
    if (actionId == _logoutAction) _logout();
  }

  /// Todos/posts may have changed on the screens opened from the menu.
  ///
  /// Called by `ScreenEffectListener` when a page opened from the menu is
  /// closed; reloads the summary silently (no loader) so the numbers stay
  /// up to date without a flicker.
  @override
  void onNavigationReturn(Object? result) {
    load(showLoader: false);
  }

  /// Signs the user out and returns to the login page.
  ///
  /// Triggered by [onConfirmed]. Emits a navigation effect that clears the
  /// back stack (so "back" cannot reopen the dashboard), or an error
  /// snackbar when logout fails.
  Future<void> _logout() async {
    try {
      await _authRepository.logout();
      navigateTo(RouteNames.login, mode: NavigationStyle.clearStack);
    } on Object catch (error) {
      showError(error);
    }
  }
}
