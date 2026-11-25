import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/users/screens/user_details/cubit/user_details_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

/// Business logic of the user details screen: one user and their posts.
class UserDetailsCubit extends ScreenCubit<UserDetailsBuildState> {
  /// Creates the Cubit for the user [userId]. Repositories come from GetIt.
  UserDetailsCubit({
    required this.userId,
    required this._userRepository,
    required this._postRepository,
  }) : super(const UserDetailsBuildState(), name: 'UserDetailsCubit');

  /// Request purpose (used with [newRequestToken]) of the full load.
  static const String _loadRequest = 'load';

  /// Request purpose of the quiet posts-only reload. It has its own purpose
  /// so it does not cancel a running full load (and vice versa).
  static const String _postsRequest = 'posts';

  /// Id of the user shown on this screen (route argument).
  final int userId;

  /// Source of the user.
  final UserRepository _userRepository;

  /// Source of the user's posts.
  final PostRepository _postRepository;

  // Working data. The immutable state is rebuilt from these fields.

  /// Loading status of the screen.
  ViewStatus _status = ViewStatus.initial;

  /// The loaded user; `null` until loaded.
  UserModel? _user;

  /// The user's posts.
  List<PostModel> _posts = const <PostModel>[];

  /// Message shown by the error view.
  String? _errorMessage;

  /// Builds a new state from the working data and emits it.
  void _render() {
    emitBuild(
      UserDetailsBuildState(
        status: _status,
        user: _user,
        posts: List<PostModel>.unmodifiable(_posts),
        errorMessage: _errorMessage,
      ),
    );
  }

  /// Loads the user and the user's posts at the same time.
  ///
  /// Triggered when the screen opens (by the route) and by the retry button
  /// of the error view. Emits a loading state, then the loaded state, or an
  /// error state plus an error snackbar.
  Future<void> load() async {
    final RequestToken token = startBlockingRequest(_loadRequest);
    _status = ViewStatus.loading;
    _errorMessage = null;
    _render();
    try {
      // Filled by the two parallel requests below; `late` because they get
      // their values inside the callbacks.
      late final UserModel user;
      late final List<PostModel> posts;
      // Both requests run in parallel. Future.wait rethrows the first error
      // unchanged, so the error message stays meaningful.
      await Future.wait(<Future<void>>[
        _userRepository.getUser(userId, requestToken: token).then((
          UserModel value,
        ) {
          user = value;
        }),
        _postRepository.getPostsByUser(userId, requestToken: token).then((
          List<PostModel> value,
        ) {
          posts = value;
        }),
      ]);
      _user = user;
      _posts = posts;
      _status = ViewStatus.loaded;
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

  /// Called when a post in `UserPostsSection` is tapped.
  /// Emits a navigation effect that opens the details page of [post].
  void onPostTapped(PostModel post) {
    navigateTo(RouteNames.postDetails, arguments: post.id);
  }

  /// Called by `ScreenEffectListener` when the user comes back from a post
  /// page: the post may have been edited or deleted, so the list is reloaded
  /// quietly (no loader).
  @override
  void onNavigationReturn(Object? result) {
    _reloadPosts();
  }

  /// Reloads only the posts, without showing the loader.
  ///
  /// Emits the new posts, or an error snackbar (the old posts stay visible).
  Future<void> _reloadPosts() async {
    final RequestToken token = newRequestToken(_postsRequest);
    try {
      _posts = await _postRepository.getPostsByUser(
        userId,
        requestToken: token,
      );
      _render();
    } on Object catch (error) {
      if (isCancellation(error)) {
        return;
      }
      showError(error);
    }
  }
}
