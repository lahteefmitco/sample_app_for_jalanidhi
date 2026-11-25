import 'package:flutter/foundation.dart';
import 'package:sample_app_for_jalanidhi/core/state/screen_state.dart';
import 'package:sample_app_for_jalanidhi/core/state/view_status.dart';
import 'package:sample_app_for_jalanidhi/global/models/user_model.dart';

/// What the post form renders: status, authors, selection and field errors.
///
/// The typed title and body are not here: they live in the Cubit's text
/// controllers, so typing does not need a new state.
@immutable
class PostFormBuildState {
  /// Creates the build state. By default nothing has been loaded yet.
  const PostFormBuildState({
    this.status = ViewStatus.initial,
    this.users = const <UserModel>[],
    this.selectedUserId,
    this.titleError,
    this.bodyError,
    this.errorMessage,
  });

  /// Decides what the screen shows: loader, error view or the form.
  final ViewStatus status;

  /// Every user, used as the entries of the author dropdown.
  final List<UserModel> users;

  /// Id of the author selected in the dropdown.
  final int? selectedUserId;

  /// Validation message under the title field; `null` when valid.
  final String? titleError;

  /// Validation message under the body field; `null` when valid.
  final String? bodyError;

  /// Message shown by the error view when [status] is error.
  final String? errorMessage;

  /// Text used in logs; prints only the number of users.
  @override
  String toString() =>
      'PostFormBuildState(status: $status, users: ${users.length}, '
      'selectedUserId: $selectedUserId, titleError: $titleError, '
      'bodyError: $bodyError, errorMessage: $errorMessage)';
}

/// Full state of the post form screen: the build state plus the one-time
/// effect (progress, snackbar, closing the page …). Short name used by
/// widgets and the Cubit.
typedef PostFormState = ScreenState<PostFormBuildState>;
