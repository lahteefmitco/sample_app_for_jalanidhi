import 'package:material_ui/material_ui.dart';
import 'package:sample_app_for_jalanidhi/core/errors/error_handler.dart';
import 'package:sample_app_for_jalanidhi/core/network/request_token.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_cubit.dart';
import 'package:sample_app_for_jalanidhi/core/state/ui_effect.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/core/utils/app_logger.dart';
import 'package:sample_app_for_jalanidhi/core/utils/validators.dart';
import 'package:sample_app_for_jalanidhi/features/posts/screens/post_form/cubit/post_form_state.dart';
import 'package:sample_app_for_jalanidhi/global/models/post_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/post_repository.dart';
import 'package:sample_app_for_jalanidhi/global/repositories/user_repository.dart';

/// Cubit of the post form. Creates a post, or edits an existing one when
/// [postId] is not null.
///
/// It loads the list of authors (and the post when editing), validates the
/// fields and saves. The page closes itself with the result `'saved'`.
class PostFormCubit extends ScreenCubit<PostFormBuildState> {
  /// Creates the Cubit. [postId] is the route argument (`null` = new post);
  /// repositories are injected by GetIt.
  PostFormCubit({
    required this.postId,
    required this._postRepository,
    required this._userRepository,
  }) : super(const PostFormBuildState(), name: 'PostFormCubit');

  /// Request purpose used with [newRequestToken].
  static const String _loadRequest = 'load';

  /// Id of the post to edit; `null` when creating a new post.
  final int? postId;

  /// Loads the post to edit and saves (creates/updates) the post.
  final PostRepository _postRepository;

  /// Source of the authors shown in the author dropdown.
  final UserRepository _userRepository;

  /// Controller of the title field. Owned by the Cubit, disposed in [close].
  final TextEditingController titleController = TextEditingController();

  /// Controller of the body field. Owned by the Cubit, disposed in [close].
  final TextEditingController bodyController = TextEditingController();

  // ---------------------------------------------------------------------------
  // Working data. The immutable build state is rebuilt from these fields.
  // ---------------------------------------------------------------------------

  /// Loading status of the form (loader, error view or the fields).
  ViewStatus _status = ViewStatus.initial;

  /// Every user, for the author dropdown.
  List<UserModel> _users = const <UserModel>[];

  /// Author chosen in the dropdown; `null` when there are no users.
  int? _selectedUserId;

  /// Validation message under the title field; `null` when valid.
  String? _titleError;

  /// Validation message under the body field; `null` when valid.
  String? _bodyError;

  /// Message shown by the error view when loading failed.
  String? _errorMessage;

  /// `true` when editing an existing post, `false` when creating a new one.
  /// The screen uses it to choose the page title.
  bool get isEdit => postId != null;

  /// Builds a new state from the working data and emits it.
  void _render() {
    emitBuild(
      PostFormBuildState(
        status: _status,
        users: _users,
        selectedUserId: _selectedUserId,
        titleError: _titleError,
        bodyError: _bodyError,
        errorMessage: _errorMessage,
      ),
    );
  }

  /// Loads the authors and, when editing, the post to fill the fields with.
  ///
  /// Triggered when the screen opens (by the route) and by the retry button
  /// of the error view. Emits a loading state, then the loaded state, or an
  /// error state plus an error snackbar.
  ///
  /// A load that is still running is cancelled first.
  Future<void> load() async {
    final RequestToken token = startBlockingRequest(_loadRequest);
    _status = ViewStatus.loading;
    _errorMessage = null;
    _render();
    try {
      _users = await _userRepository.getUsers(requestToken: token);
      // New post: preselect the first author (if any).
      _selectedUserId = _users.isEmpty ? null : _users.first.id;
      // Copied into a local so Dart can promote it to a non-null `int`.
      final int? id = postId;
      if (id != null) {
        // Edit mode: fill the fields with the existing post.
        final PostModel post = await _postRepository.getPost(
          id,
          requestToken: token,
        );
        titleController.text = post.title;
        bodyController.text = post.body;
        _selectedUserId = post.userId;
      }
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

  /// Called by the author dropdown in `PostFormFields` when another author
  /// is picked. Emits the new selection; `null` is ignored.
  void onUserChanged(int? userId) {
    if (userId == null) return;
    _selectedUserId = userId;
    _render();
  }

  /// Called by the save button in `PostFormFields`.
  ///
  /// Validates, then creates or updates the post. Emits the field errors
  /// first; if valid, emits progress, then pops the screen with the result
  /// `'saved'`, or hides progress and shows an error snackbar.
  ///
  /// Not cancellable on purpose: a save should finish once started.
  Future<void> submit() async {
    // A request is already running: ignore a second tap / Enter key press.
    if (isBusy) {
      return;
    }
    // Values without leading/trailing spaces, as they will be saved.
    final String title = titleController.text.trim();
    final String body = bodyController.text.trim();
    // Copied into a local so Dart can promote it to a non-null `int`.
    final int? userId = _selectedUserId;

    _titleError = Validators.required(title);
    _bodyError = Validators.required(body);
    _render();
    // Stop here when a field is invalid (the errors are now visible).
    if (_titleError != null || _bodyError != null || userId == null) return;

    cubitLog(
      'submit: ${isEdit ? 'update' : 'create'} post',
      funtionName: 'submit',
    );
    showProgress();
    try {
      // Copied into a local so Dart can promote it to a non-null `int`.
      final int? id = postId;
      if (id == null) {
        await _postRepository.createPost(
          userId: userId,
          title: title,
          body: body,
        );
      } else {
        await _postRepository.updatePost(
          PostModel(id: id, userId: userId, title: title, body: body),
        );
      }
      hideProgress();
      // The previous screen shows the "saved" message when it gets the result.
      emitEffect(const PopEffect('saved'));
    } on Object catch (error) {
      hideProgress();
      showError(error);
    }
  }

  /// Disposes the text controllers, cancels requests and closes the Cubit.
  ///
  /// Called automatically by `BlocProvider` when the screen is removed.
  @override
  Future<void> close() {
    titleController.dispose();
    bodyController.dispose();
    return super.close();
  }
}
