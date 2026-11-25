import 'package:sample_app_for_jalanidhi/core/constants/app_strings.dart';
import 'package:sample_app_for_jalanidhi/core/constants/route_names.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_details/cubit/post_details_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/comment_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/comment_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

/// Business logic of the post details screen: the post, its author and its
/// comments, plus the edit and delete actions.
class PostDetailsCubit extends ScreenCubit<PostDetailsBuildState> {
  /// Creates the Cubit for the post [postId]. Repositories come from GetIt.
  PostDetailsCubit({
    required this.postId,
    required this._postRepository,
    required this._userRepository,
    required this._commentRepository,
  }) : super(const PostDetailsBuildState(), name: 'PostDetailsCubit');

  /// Request purpose used with [newRequestToken].
  static const String _loadRequest = 'load';

  /// Id of the "delete this post" confirmation.
  static const String _deleteAction = 'delete';

  /// Id of the post shown on this screen (route argument).
  final int postId;

  /// Source of the post.
  final PostRepository _postRepository;

  /// Source of the author.
  final UserRepository _userRepository;

  /// Source of the comments.
  final CommentRepository _commentRepository;

  // Working data. The immutable state is rebuilt from these fields.

  /// Loading status of the screen.
  ViewStatus _status = ViewStatus.initial;

  /// The loaded post; `null` until loaded.
  PostModel? _post;

  /// The author of the post; `null` until loaded.
  UserModel? _author;

  /// Comments of the post.
  List<CommentModel> _comments = const <CommentModel>[];

  /// Message shown by the error view.
  String? _errorMessage;

  /// Builds a new state from the working data and emits it.
  void _render() {
    emitBuild(
      PostDetailsBuildState(
        status: _status,
        post: _post,
        author: _author,
        comments: List<CommentModel>.unmodifiable(_comments),
        errorMessage: _errorMessage,
      ),
    );
  }

  /// Loads the post, then its author and comments at the same time.
  ///
  /// Triggered when the screen opens (by the route), by the retry button of
  /// the error view, and quietly by [onNavigationReturn].
  /// Emits a loading state (only when [showLoader]), then the loaded state,
  /// or an error state plus an error snackbar.
  ///
  /// [showLoader] is `false` for quiet reloads (e.g. back from the form).
  /// A load that is still running is cancelled first.
  Future<void> load({bool showLoader = true}) async {
    final RequestToken token = startBlockingRequest(_loadRequest);
    if (showLoader) {
      _status = ViewStatus.loading;
      _errorMessage = null;
      _render();
    }
    try {
      // The post comes first: its `userId` is needed to load the author.
      final PostModel post = await _postRepository.getPost(
        postId,
        requestToken: token,
      );
      // Filled by the two parallel requests below; `late` because they get
      // their values inside the callbacks.
      late final UserModel author;
      late final List<CommentModel> comments;
      // Both requests run in parallel; Future.wait rethrows the first error.
      await Future.wait(<Future<void>>[
        _userRepository.getUser(post.userId, requestToken: token).then((
          UserModel value,
        ) {
          author = value;
        }),
        _commentRepository.getCommentsByPost(postId, requestToken: token).then((
          List<CommentModel> value,
        ) {
          comments = value;
        }),
      ]);
      _post = post;
      _author = author;
      _comments = comments;
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

  /// Called by the edit button in the app bar.
  /// Emits a navigation effect that opens the post form filled with this post.
  void onEditPressed() {
    navigateTo(RouteNames.postForm, arguments: postId);
  }

  /// Called by the delete button in the app bar.
  /// Emits a confirmation-dialog effect; nothing is deleted until the user
  /// confirms (see [onConfirmed]).
  void onDeletePressed() {
    emitEffect(
      const ShowConfirmationEffect(
        actionId: _deleteAction,
        title: AppStrings.confirmDeletePostTitle,
        message: AppStrings.confirmDeletePostMessage,
        confirmLabel: AppStrings.delete,
        // Deleting cannot be undone: the dialog turns red.
        isDestructive: true,
      ),
    );
  }

  /// Called when a comment in `PostCommentsSection` is tapped.
  /// Emits an effect that opens a bottom sheet with the full [comment].
  void onCommentTapped(CommentModel comment) {
    emitEffect(
      ShowInfoSheetEffect(
        title: 'Comment #${comment.id}',
        fields: <MapEntry<String, String>>[
          MapEntry<String, String>('Name', comment.name),
          MapEntry<String, String>('Email', comment.email),
          MapEntry<String, String>('Post', '#${comment.postId}'),
          MapEntry<String, String>('Body', comment.body),
        ],
      ),
    );
  }

  /// Called by `ScreenEffectListener` after the user confirms a dialog.
  /// Only the delete confirmation exists on this screen.
  @override
  void onConfirmed(String actionId) {
    if (actionId == _deleteAction) {
      _delete();
    }
  }

  /// Deletes the post, then closes the screen with the result `'deleted'`.
  ///
  /// Emits: progress shown, then progress hidden and a pop effect; or
  /// progress hidden and an error snackbar.
  ///
  /// Not cancellable on purpose: a delete should finish once started.
  Future<void> _delete() async {
    // A request is already running: ignore a second tap / Enter key press.
    if (isBusy) {
      return;
    }
    showProgress();
    try {
      await _postRepository.deletePost(postId);
      hideProgress();
      // The list screen shows the "deleted" message when it gets the result.
      emitEffect(const PopEffect('deleted'));
    } on Object catch (error) {
      hideProgress();
      showError(error);
    }
  }

  /// Called by `ScreenEffectListener` when the user comes back from the edit
  /// form: reloads the (possibly edited) post quietly and shows a success
  /// snackbar when the form returned `'saved'`.
  @override
  void onNavigationReturn(Object? result) {
    load(showLoader: false);
    if (result == 'saved') {
      showSuccessMessage(AppStrings.postSaved);
    }
  }
}
